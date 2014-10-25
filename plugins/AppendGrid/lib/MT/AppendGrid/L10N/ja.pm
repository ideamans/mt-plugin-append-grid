package MT::AppendGrid::L10N::ja;

use strict;
use utf8;
use base 'MT::AppendGrid::L10N::en_us';
use vars qw( %Lexicon );

%Lexicon = (

## config.yaml
	'Adds grid customfield type with appendGrid.' => 'appendGridによるグリッドテーブルのカスタムフィールドを追加します。',
    'Grid Table with appendGrid configured by JSON' => 'appendGrid グリッドテーブル(JSON設定)',

## lib/MT/AppendGrid/Schema.pm
    'AppendGrid Schema' => 'AppendGridスキーマ',
    'AppendGrid Schemas' => 'AppendGridスキーマ',
    '[_1] is not in a JSON format.' => '[_1]はJSON形式ではありません。',
    'Schema YAML or JSON is malformed.' => 'スキーマがYAMLまたはJSONの形式として正しくありません。',

## lib/MT/AppendGrid/CMS/Schema.pm
    'Name is required.' => '名前は必須項目です。',

## lib/MT/AssetGrid/CustomFields.pm
    'JSON is not parsable because [_1]: [_2]' => '解析できないJSONデータです(理由: [_1]): [_2]',
    'JSON data must be an array of hash: [_1]' => 'JSONデータはハッシュの配列である必要があります: [_1]',

## lib/MT/AppendGrid/Tag.pm
    'AppendGrid Customfield which basename is "[_1]" is not found.' => '"[_1]"というベースネームのカスタムフィールドは存在しません。',
    'AppendGrid Customfield has no JSON hash schema.' => 'AppendGridのスキーマがJSON形式ではないか、ハッシュデータではありません。',
    'AppendGrid Customfield has no columns array in schema.' => 'AppendGridのスキーマにcolumns配列がありません。',
    'AppendGrid has invalid column definision in columns.' => 'AppendGridのスキーマの列定義にハッシュではない列が含まれています。',
    'AppendGrid has column without name in column definition.' => 'AppendGridのスキーマの列定義にname値を持たない列が含まれています。',
    'AppendGrid data is not JSON format.' => 'AppendGridデータがJSON形式ではありません。',
    'AppendGrid data is not an array of hash.' => 'AppendGridデータがハッシュ配列ではありません。',
    'Use mt:[_1] tag with col attribute or inside mt:AppendGridColumns.'
        => 'mt:[_1]テンプレートタグは、colまたはcolumn属性を指定するか、mt:AppendGridColumnsテンプレートタグの内部で使用してください。',
    'No AppendGrid schema context. Set AppendGrid customfield basename as basename attribute of AppendGridColumns or AppendGrid template tag.'
        => 'AppendGridスキーマがコンテキストにありません。mt:AppendGridColumnsまたは上位のmt:AppendGridテンプレートタグにbasename属性としてAppendGridカスタムフィールドのベースネームを指定してください。',
    'No AppendGrid data context. Set AppendGrid tag as tag attribute or set JSON data as data attribute of AppendGridRows, AppendGrid template tag.'
        => 'AppendGridデータがコンテキストにありません。mt:AppendGridrow(s)または上位のmt:AppendGridテンプレートタグにtag属性としてカスタムフィールドタグを指定するか、data属性としてJSONデータを指定してください。',
    '[_1] template tag requires [_2] attribute.' => '[_1]テンプレートタグには[_2]属性が必要です。',
    'No AppendGrid row context. Set index as row attribute of AppendGridRow template tag or use in AppendGridRows template tag.'
        => 'AppendGrid行データがコンテキストにありません。mt:AppendGridRowにrow属性として行インデックスを指定するか、AppendGridRowsテンプレートタグの内部で使用してください。',
    'No AppendGrid column context. Use in AppendGridColumns template tag.' => 'AppendGrid列情報がコンテキストにありません。mt:AppendGridColumnsテンプレートタグの内部で使用してください。',
    'mt:[_1] template tag requires at least one of [_2] as attributes.' => 'mt:[_1]テンプレートタグは、[_2]のいずれかの属性が必要です。',
    'No column definition named "[_1]".' => '"[_1]"というnameの列定義は存在しません。',
    'No column indexed [_1].' => 'インデックス[_1]の列定義は存在しません。',

## tmpl/append_grid_with_json
    'Append' => '追加',
    'Remove Last' => '最後を削除',
    'Insert Above' => '上に挿入',
    'Remove' => '削除',
    'Move Up' => '上に移動',
    'Move Down' => '下に移動',
    'Move Row With Drag & Drop' => 'ドラッグ＆ドロップで行を移動',
    'No Row' => '行がありません',

## tmpl/cms/edit_append_grid_schema.tmpl
    'Edit AppendGrid Schema' => 'AppendGridスキーマの編集',
    'Create AppendGrid Schema' => 'AppendGridスキーマの作成',
    'Schema JSON' => 'スキーマJSON',
    'Schema YAML' => 'スキーマYAML',
    'Save changes to this schema (s)' => 'このスキーマを保存する',

## tmpl/cms/list_append_grid_schema.tmpl
    'The schema has been deleted from the database.' => 'スキーマが削除されました。',
);

1;

