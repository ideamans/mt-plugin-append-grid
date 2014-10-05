package MT::AppendGrid::L10N::ja;

use strict;
use utf8;
use base 'MT::AppendGrid::L10N::en_us';
use vars qw( %Lexicon );

%Lexicon = (

## config.yaml
	'Adds grid customfield type with appendGrid.' => 'appendGridによるグリッドテーブルのカスタムフィールドを追加します。',
    'Grid Table with appendGrid configured by JSON' => 'appendGrid グリッドテーブル(JSON設定)',

## lib/MT/AssetGrid/CustomFields.pm
    'JSON is not parsable because [_1]: [_2]' => '解析できないJSONデータです(理由: [_1]): [_2]',
    'JSON data must be an array of hash: [_1]' => 'JSONデータはハッシュの配列である必要があります: [_1]',

## tmpl/append_grid_with_json
    'Append' => '追加',
    'Remove Last' => '最後を削除',
    'Insert Above' => '上に挿入',
    'Remove' => '削除',
    'Move Up' => '上に移動',
    'Move Down' => '下に移動',
    'Move Row With Drag & Drop' => 'ドラッグ＆ドロップで行を移動',
    'No Row' => '行がありません',
);

1;

