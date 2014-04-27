=head1 ABOUT

CalDAV::Sender - fetch remote calenders and push them to a CalDAV server

=head1 SYNOPSIS

 use CalDAV::Sender;


=cut

package CalDAV::Sender;
use Moose;
use MooseX::Params::Validate;
use utf8;

use LWP;
use File::Temp qw/tempfile/;

BEGIN { $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0 }

my $ua = LWP::UserAgent->new;
$ua->agent("CalDAV-Sender/0.1 ");

=head1 METHODS

=head2 new

 $cs = CalDAV::Sender->new( $url );

=cut

sub BUILDARGS {
	my ($class, $url) = pos_validated_list(\@_, {isa => q/ClassName/}, {isa => q/Str/});
	$url =~ s/\/+$//gis;
	return {url => $url};
}

=head2 url

 $url_string = $cs->url();

Returns the base adress of the destination calendar server.

=cut

has url => (
		is => q/ro/,
		isa => q/Str/,
		required => 1,
	);

has username => (
		is => q/rw/,
		isa => q/Maybe[Str]/,
	);
has password => (
		is => q/rw/,
		isa => q/Maybe[Str]/,
	);


=head2 process

 $bool = $cs->process( 
		$calendar_name_1 => $src_url_1,
		$calendar_name_2 => $src_url_2,
		...
	);

Processes the given calendars using the L<process_calendar method|/process_calendar>.

=cut

sub process {
	my ($self, $feeds) = pos_validated_list(\@_, {isa => __PACKAGE__}, {isa => q/HashRef[Str]/});
	foreach my $calendar (keys %$feeds){
		$self->process_calendar($calendar, $feeds->{$calendar});
	};
}

=head2 process_calendar

 $bool = $cs->process_calendar($calendar_name, $src_url);

Processes the update of a single calendar. The data is fetched
from the C<$src_url>. The existence of
the destination calendar is ensured and finally, the content is
pushed to the destionation.

=cut

sub process_calendar {
	my ($self, $calendar, $url) = pos_validated_list(\@_, {isa => __PACKAGE__}, {isa => q/Str/}, {isa => q/Str/});
	print STDERR qq/Processing $calendar...\n/;

	print qq/\tChecking existence of CalDAV calendar: $calendar\n/;
	my $url_full = $self->check_calendar($calendar)
		or return;

	print qq/\tFetching: $url\n/;
	my $data = $self->fetch($url)
		or return;
	
	print qq/\tSending: $url_full\n/;
	$self->send($url_full, $data)
		or return;

	return 1;
}

=head2 check_calendar

 $url_full = $cs->check_calendar($calendar_id);

Ensures that the given calendar exists and is writable. The
full URL to that calendar ist returned.

=cut

sub check_calendar {
	my ($self, $calendar) = pos_validated_list(\@_, {isa => __PACKAGE__}, {isa => q/Str/});
	my $url_full = sprintf(q(%s/%s), $self->url, $calendar);
	print qq/\t\tFull url: $url_full\n/;
	
	my $request = $self->_request(GET => $url_full);
	my $response = $ua->request($request);
	if( ! $response->is_success ){
		if( $response->code == 404 ){
			my $request_create = $self->_request(MKCALENDAR => $url_full);
			$request_create->add_content_utf8(q(<?xml version="1.0" encoding="utf-8" ?>
   <C:mkcalendar xmlns:D="DAV:"
                 xmlns:C="urn:ietf:params:xml:ns:caldav">
     <D:set>
       <D:prop>
         <D:displayname>).$calendar.q(</D:displayname>
         <C:calendar-description xml:lang="en">Automatic created calendar by ). __PACKAGE__ .q(</C:calendar-description>
         <C:supported-calendar-component-set>
           <C:comp name="VEVENT"/>
         </C:supported-calendar-component-set>
	  </D:prop>
     </D:set>
   </C:mkcalendar>));

			my $response_create = $ua->request($request_create);
			if( $response_create->code != 201 ){
				print STDERR qq/Calendar does not exist and can not be created: $url_full/;
				print STDERR $response_create->status_line;
				return;
			}
		}
		else {
			die $response->status_line;
		}
	}

	return $url_full;
}

=cut fetch

 $content = $cs->fetch($url);

Downloads and returns the contents located at C<$url>.
The returned content will be a decoded string.

=cut

sub fetch {
	my ($self, $url) = pos_validated_list(\@_, {isa => __PACKAGE__}, {isa => q/Str/});
	
	my $request = HTTP::Request->new(GET => $url);
	$request->accept_decodable;
	my $response = $ua->request($request);
	if( ! $response->is_success ){
		printf STDERR qq/Can not fetch '$url': %s\n/, $response->status_line;
		return;
	}

	return ($response->decoded_content);
}

=head2 send

 $bool = $cs->send($dest_url, $data);

Pushes the data to the given url. The data has to be in valid ICS format.
Returns a true value on success.

=cut

sub send {
	my ($self, $url_full, $data) = pos_validated_list(\@_, {isa => __PACKAGE__}, {isa => q/Str/}, {isa => q/Str/});
	my $request = $self->_request(PUT => $url_full);
	$request->header(q(Content-Type) => q(text/calendar));
	$request->add_content_utf8($data);

	my $response = $ua->request($request);
	if( ! $response->is_success ){
		printf STDERR qq/ERROR: %s - %s\n%s\n/, $response->code, $response->status_line, $response->decoded_content;
	}
	return $response->is_success;
}


sub _request {
	my ($self, $method, $url) = pos_validated_list(\@_, {isa => __PACKAGE__}, {isa => q/Str/}, {isa => q/Str/});
	my $request = HTTP::Request->new($method => $url);
	if( $self->username && $self->password ){
		$request->authorization_basic($self->username, $self->password);
	}
	return $request;
}

__PACKAGE__->meta->make_immutable();

=head1 AUTHOR

Manuel Landesfeind <manuel@landesfeind.de>

=head2 COPYRIGHT

All rights reserved.

