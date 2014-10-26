package MT::AppendGrid::L10N::en_us;

use strict;
use utf8;

use base 'MT::AppendGrid::L10N';
use vars qw( %Lexicon );
%Lexicon = ();

$Lexicon{_default_options_yaml} = <<'YAML';
columns:
    -
        name: album
        display: アルバム
        ctrlAttr:
            maxlength: 100
        ctrlCss:
            width: 160px
    -
        name: artist
        display: アーティスト
        ctrlAttr:
            maxlength: 100
        ctrlCss:
            width: 100px
initData:
    -
        album: Dearest
        artist: Theresa Fu
YAML

$Lexicon{_default_options_json} = <<'EOJ';
{
    "columns": ~[
        {
            "name": "Album",
            "display": "アルバム",
            "type": "text",
            "ctrlAttr": { "maxlength": 100 },
            "ctrlCss": { "width": "160px" }
        },
        {
            "name": "Artist",
            "display": "アーティスト",
            "type": "text",
            "ctrlAttr": { "maxlength": 100 },
            "ctrlCss": { "width": "100px"}
        }
    ~],
    "initData": ~[
        { "Album": "Dearest", "Artist": "Theresa Fu", "Year": "2009", "Price": 168.9 },
        { "Album": "To be Free", "Artist": "Arashi", "Year": "2010", "Price": 152.6 }
    ~]
}
EOJ

1;
