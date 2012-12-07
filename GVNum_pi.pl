#!/usr/local/bin/perl
use strict;
use warnings;
use WWW::Mechanize;
use URI::Escape;
use JSON;

# Takes a hash and outputs a GET query string
sub escape_hash {
    my %hash = @_;
    my @pairs;
    for my $key (keys %hash) {
        push @pairs, join "=", map { uri_escape($_) } $key, $hash{$key};
    }
    return join "&", @pairs;
}

# Reads a file as a whole into a string
sub read_file {
    my $filename = shift;
    local($/, *FH);
    open(FH, $filename);
    my $text = <FH>;
    close(FH);
    return $text;
}

#Open the settings file
#To get username, password, area code, etc
my %settings = ();
open(CFG,'pi.cfg');
while(<CFG>) {
    (my $param,my $val) = split(/\=/);
    chomp($val);
    $settings{$param} = $val;
}

#Read in the digits of pi and strip non-digits
my $pi = read_file('pi.txt');
$pi =~ s/[^0-9]//mg;

#Log in to Google, to get cookies and such in place
print "Logging in to Google...\n";
my $mech = WWW::Mechanize->new(autocheck=>0);
$mech->agent_alias('Windows Mozilla');
$mech->get('https://accounts.google.com/ServiceLogin');
$mech->submit_form(
    'fields' => {
        'Email'=>$settings{'email'},
        'Passwd'=>$settings{'password'},
    }
);

my $apiurl = "https://www.google.com/voice/b/0/setup/searchnew/";
my $pagepos = 0;

#Params:
#ac - Area Code
#start - pagination
#country (e.g. US)
#q - search phrase

my %done_prefixes;
my @avail;
my $area_code = $settings{'area_code'};  # We use this embedded in strings below
my $success = 0;
my $numtried = 0;

# Main loop - run through the pages, gathering possible
# prefixes to search for, match them to pi, and check
# for the availability of each matching sequence
do {
    # Set up the params for the GET request
    my %params = (
        ac => $area_code,
        start => $pagepos,
        country => $settings{'country'},
    );
    my $paramstr = escape_hash %params;

    # Ask Google for the next set of numbers in our area code
    my %response = ();
    print "Fetching $paramstr...\n";
    my $resp_obj = $mech->get("$apiurl?$paramstr");

    # Default to failure - if we get an error response
    # This will exit the loop
    # This is also how the program knows it's out of numbers
    # Since Google returns a 404
    $success = 0;

    if($resp_obj->code == 200) { 
        # Get the response JSON
        my $response = decode_json($mech->content());
        my $numlist = $response->{'JSON'}->{'vanity_info'};

        # Run through the prefixes, matching them
        # against the ones we've already tried
        # to make sure we only try new ones
        my %prefixes;
        foreach (keys(%$numlist)) {
            /\+1(\d{3,3})(\d{3,3})(\d{4,4})/;
            unless(exists $done_prefixes{$2}) {
                $prefixes{$2} = 1;
                $done_prefixes{$2} = 1;
            }
        }
        
        my $numresults = keys(%$numlist);
        $pagepos += $numresults;

        # Run through new prefixes, looking for 
        # all matches of the area code and prefix
        # in the given digits of pi
        foreach my $pre (keys(%prefixes)) {
            print "Searching for prefix $pre\n";
            # Ask Google about each match
            while($pi =~ /($area_code$pre\d{4,4})/g) {
                # Add the full number as the query, and re-generate the params
                $params{'q'} = $1;
                my $paramstr = escape_hash %params;

                $numtried++;
                print "  Trying $1...";
                $mech->get("$apiurl?$paramstr");
                my $response = decode_json($mech->content());

                # Check num_matches to see if we got any
                my $found = $response->{'JSON'}->{'num_matches'};
                if($found > 0) {
                    print "available!\n";
                    push(@avail, $found); # Keep track of found numbers for later
                } else {
                    print "nope.\n";
                }
            }
        }

        # Also stop if we didn't get any hits this time
        $success = $numresults;
    }
} while($success);

my $numfound = $#avail + 1;
# Let the user know what we found
if($numfound) {
    my $numlist = join("\n",@avail);
    print "Found $numtried candidates, $numfound available:\n$numlist\n";
} else {
    print "Found $numtried candidates, none available.\n";
}
