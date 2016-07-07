=item
Library                      Test number  Items num  Encoded size  Encode time  Decode time
-------------------------------------------------------------------------------------------
DR::Tarantool::MsgPack       #1 arrayref  26         29            0.195533     0.429747
DR::Tarantool::MsgPack       #2 arrayref  26         55            0.348736     0.687626
DR::Tarantool::MsgPack       #3 arrayref  100        103           0.561112     1.175445
DR::Tarantool::MsgPack       #4 hashref   26         55            1.413119     1.340451
DR::Tarantool::MsgPack       #5 hashref   100        203           5.237450     4.696461
DR::Tarantool::MsgPack       #6 hashref   100        303           5.834627     7.635587

Data::MessagePack 0.50       #1 arrayref  26         29            0.155088     0.324980
Data::MessagePack 0.50       #2 arrayref  26         81            0.222192     0.589528
Data::MessagePack 0.50       #3 arrayref  100        103           0.435715     0.876896
Data::MessagePack 0.50       #4 hashref   26         123           1.471963     1.041418
Data::MessagePack 0.50       #5 hashref   100        493           6.174683     3.707380
Data::MessagePack 0.50       #6 hashref   100        593           6.646406     6.337818

JSON::XS 2.34                #1 arrayref  26         69            0.181673     0.322304
JSON::XS 2.34                #2 arrayref  26         105           0.179327     0.576198
JSON::XS 2.34                #3 arrayref  100        291           0.551505     1.034891
JSON::XS 2.34                #4 hashref   26         189           0.287503     0.601269
JSON::XS 2.34                #5 hashref   100        781           0.888018     2.280801
JSON::XS 2.34                #6 hashref   100        981           1.315101     5.184966
=cut

use DR::Tarantool::MsgPack qw/msgpack msgunpack/;
use Data::MessagePack;
use JSON::XS;
use Time::HiRes qw/gettimeofday tv_interval/;

use strict;
use warnings;
use bytes;

my $iter = 100_000;

my @result;
my $mp = Data::MessagePack->new();

for my $lib (
	['DR::Tarantool::MsgPack', \&msgpack, \&msgunpack],
	['Data::MessagePack', sub {$mp->pack($_[0])}, sub {$mp->unpack($_[0])}],
	['JSON::XS', \&encode_json, \&decode_json],
) {
	my $test_number = 0;
	for my $struct (
		[0 .. 25],
		['a' .. 'z'],
		[0 .. 99],
		{map {$_ => $_} (0 .. 25)},
		{map {$_ => $_} (0 .. 99)},
		{map {$_ => [$_]} (0 .. 99)},
	) {
		my ($name, $encode, $decode) = @$lib;

		my ($packed, $unpacked);

		my %res = (
			lib		=> $name . ' ' . ($name->VERSION || ''),
			type	=> '#' . ++$test_number . ' ' . lc(ref $struct) . 'ref',
			items	=> scalar(ref $struct eq 'ARRAY' ? @$struct : keys(%$struct)),
		);

		my $t0 = [gettimeofday];
		for (0 .. $iter) {$packed = $encode->($struct)}
		$res{encode_time} = sprintf '%0.6f', tv_interval $t0;
		$res{encode_size} = length $packed;

		my $t1 = [gettimeofday];
		for (0 .. $iter) {$unpacked = $decode->($packed)}
		$res{decode_time} = sprintf '%0.6f', tv_interval $t1;

		push @result, \%res;
	}
}

foreach my $r (@result) {
format STDOUT_TOP =
Library                      Test number  Items num  Encoded size  Encode time  Decode time
-------------------------------------------------------------------------------------------
.
format STDOUT =
@<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<< @<<<<<<<<< @<<<<<<<<<<<< @<<<<<<<<<<< @<<<<<<<<<<
$$r{lib}, $$r{type}, $$r{items}, $$r{encode_size}, $$r{encode_time}, $$r{decode_time}
.
write;
}

