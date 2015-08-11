(function($) {
    $.mtAppendGrid = {
        stringify : function (obj) {
            var t = typeof (obj);
            if (t != "object" || obj === null) {
                // simple data type
                if (t == "string") obj = '"' + obj + '"';
                return String(obj);
            } else {
                // recurse array or object
                var n, v, json = [], arr = (obj && obj.constructor == Array);
                for (n in obj) {
                    v = obj[n];
                    t = typeof(v);
                    if (obj.hasOwnProperty(n)) {
                        if (t == "string") v = '"' + v.replace(/"/g, '\\"').replace(/\n/g, '\\n').replace(/\t/g, '\\t') + '"'; else if (t == "object" && v !== null) v = $.mtAppendGrid.stringify(v);
                        json.push((arr ? "" : '"' + n + '":') + String(v));
                    }
                }
                return (arr ? "[" : "{") + String(json) + (arr ? "]" : "}");
            }
        },
        safeSetupGrid: function(args) {
            try {
                $.mtAppendGrid.setupGrid(args);
            } catch ( ex ) {
                if ( console ) {
                    console.log(ex);
                } else {
                    alert(ex.message || ex);
                }
            }
        },
        setupGrid: function(args) {
            var $grid = args.grid,
                $input = args.input,
                $inputShower = args.inputShower,
                options = args.options,
                forces = $.extend(args.forces, $.mtAppendGrid.forceOptions);

            // Default options
            var defaults = $.extend({
                initRows: 3,
                rowDragging: true,
                hideButtons: { moveUp: true, moveDown: true },
                i18n: $.mtAppendGrid.i18n
            }, $.mtAppendGrid.defaultOptions);

            var opts = $.extend(defaults, options);

            // Columns
            $.each(opts.columns, function(i, col) {
                var typer = col.type ? $.mtAppendGrid.customTypes[col.type] : undefined;
                var typed = typer ? typer(options) : {};
                opts.columns[i] = $.extend(col, typed);
            });

            // Data
            var value = $input ? $input.val() : '';
            if ( value != '' ) {
                var data = JSON.parse(value);
                if ( typeof data == 'string' ) { data = JSON.parse(data); }
                if ( data && data instanceof Array ) { opts.initData = data; }
            }

            // Build options
            opts = $.extend(opts, forces);
            $grid.appendGrid(opts);

            // Serialize on submit event
            $grid.closest('form').submit(function() {
                var value = $grid.appendGrid('getAllValue');
                var json = JSON.stringify(value);

                try {
                    var str = JSON.parse(json);
                    if ( typeof str == 'string' ) { json = str; }
                } catch (ex) {}

                if ( $input )
                    $input.val(json);
                return true;
            });

            // Hide textarea
            if ( $input )
                $input.addClass('hidden');
            if ( $inputShower )
                $inputShower.removeClass('hidden');
        },
        getAsset: function(id) {
            var $wrapper = $('#' + id);
            return $wrapper.find('.append-grid-value').val();
        },
        setAsset: function(id, html) {
            var $wrapper = $('#' + id),
                $enclosure = $(html);
            var $input = $wrapper.find('.append-grid-value');

            // Value
            $input.val(html);
            if ( ! $enclosure.hasClass('mt-enclosure') ) return;

            // Build image preview
            if ( $enclosure.hasClass('mt-enclosure-image') ) {
                var $anchor = $enclosure.find('a'),
                    $img = $('<img />').css({'max-width': '160px', 'max-height': '160px'});
                $img.attr('src', $anchor.attr('href'));
                $anchor.html('').append($img);
            }

            // Preview and show remover
            $wrapper.find('.append-grid-preview').html($enclosure.html());
            $wrapper.find('.append-grid-remove-asset').removeClass('hidden');
        },
        removeAsset: function(id) {
            var $wrapper = $('#' + id);

            // Value, preview and show remover
            $wrapper.find('.append-grid-value').val('');
            $wrapper.find('.append-grid-preview').children().remove();
            $wrapper.find('.append-grid-remove-asset').addClass('hidden');
        },
        bootupCustomFieldPreview: function(me, type) {
            $.mtAppendGrid.bootupPreview(me, {
                getter: function() {
                    var data = {
                        schema_format: type,
                        schema_yaml: $('#options').val(),
                        schema_json: $('#options').val(),
                    };
                    return data;
                }
            });
        },
        bootupSchemaPreview: function(me) {
            $.mtAppendGrid.bootupPreview(me, {
                getter: function() {
                    var data = {
                        schema_format: $('#schema_format_yaml').attr('checked') ? 'yaml' : 'json',
                        schema_yaml: $('#schema_yaml').val(),
                        schema_json: $('#schema_json').val(),
                    };
                    return data;
                }
            });
        },
        bootupPreview: function(me, options) {
            var $button = $(me);
            if ( $button.data('append_grid_preview_bootup') )
                return false;

            var $wrapper = $button.closest('.preview-wrapper');
            var defaults = {
                wrapper: $wrapper,
                previewUrl: $button.attr('data-preview-uri'),
                table: $wrapper.find('.preview-table'),
                tableWrapper: $wrapper.find('.preview-table-wrapper'),
                indicator: $wrapper.find('.preview-indicator'),
                error: $wrapper.find('.preview-error'),
                button: $button,
                getter: function() { return {} }
            };

            var opts = $.extend(defaults, options);
            $.mtAppendGrid.previewer(opts);

            $button.data('append_grid_preview_bootup', true);
        },
        previewer: function(opts) {
            var $table = opts.table,
                $tableWrapper = opts.tableWrapper,
                $indicator = opts.indicator,
                $error = opts.error,
                $button = opts.button;

            var updatePreview = function() {
                $table.children().remove();
                $tableWrapper.hide();
                $error.hide();
                $indicator.fadeIn('fast');

                var data = opts.getter();

                $.post(opts.previewUrl, data)
                    .done(function(data) {
                        if ( data.error ) {
                            $error.show().find('p.msg-text').text(data.error);
                        } else if ( data.result && data.result.schema ) {
                            try {
                              $.mtAppendGrid.setupGrid({
                                  options: data.result.schema,
                                  forces: {},
                                  grid: $table,
                              });
                              $tableWrapper.fadeIn('fast');
                            } catch (ex) {
                              if ( console ) console.log(ex);
                              $error.show().find('p.msg-text').text(ex.message);
                            }
                        }
                    })
                    .fail(function(status, line, jqXHR) {
                        $error.show().find('p.msg-text').text(status + " " + line);
                    })
                    .always(function() {
                        $indicator.hide();
                    });
            };
            $button.click(updatePreview);
            updatePreview();
        },
        customTypes: {
            'tinymce': function(params) {
                // Build custom column
                return {
                    type: 'custom',
                    customBuilder: function(parent, idPrefix, name, uniqueIndex) {
                        var id = [idPrefix, name, uniqueIndex].join('_');
                        var $wrapper = $([
                            '<textarea class="text high" id="" name=""></textarea>'
                        ].join("\n"));
                        $wrapper.attr('id', id).attr('name', id);
                        $(parent).append($wrapper);

                        var manager = this.tinymce = new MT.EditorManager(id);
                        // tinymce.init({selector: '#' + id});
                        return $wrapper.get(0);
                    },
                    customGetter: function(idPrefix, name, uniqueIndex) {
                        var id = [idPrefix, name, uniqueIndex].join('_');
                        return tinymce.get(id).getContent();
                    },
                    customSetter: function(idPrefix, name, uniqueIndex, value) {
                        var id = [idPrefix, name, uniqueIndex].join('_');
                        $('#'+id).val(value);
                    }
                };
            },
            'mt-asset': function(params) {
                // Build custom column
                return {
                    type: 'custom',
                    customBuilder: function(parent, idPrefix, name, uniqueIndex) {
                        var id = [idPrefix, name, uniqueIndex].join('_');
                        var $wrapper = $([
                            '<div id="">',
                                '<input type="hidden" class="append-grid-value" />',
                                '<div class="append-grid-preview"></div>',
                                '<div class="actions-bar">',
                                    '<div class="actions-bar-inner pkg actions">',
                                        '<a href="#" class="mt-open-dialog append-grid-select-asset">',
                                        $.mtAppendGrid.translate('Select'),
                                        '</a>',
                                        '<a href="#" class="append-grid-remove-asset hidden">',
                                        $.mtAppendGrid.translate('Remove'),
                                        '</a>',
                                    '</div>',
                                '</div>',
                            '</div>',
                        ].join("\n"));

                        $wrapper.attr('id', id);

                        // filter=class&amp;filter_val=<mt:var name="asset_type">&amp;require_type=<mt:var name="asset_type">&amp;
                        var url = $.mtAppendGrid.selectAssetUrlBase;
                        url += '&amp;edit_field=' + id.replace(/customfield/, 'appendgridfield');
                        if ( params.assetType ) {
                            url += '&amp;filter=class&amp;filter_val=' + params.assetType + '&amp;require_type=' + params.assetType;
                        }

                        $wrapper.find('.append-grid-select-asset').attr('href', url).mtDialog();
                        $wrapper.find('.append-grid-remove-asset').click(function() {
                            $.mtAppendGrid.removeAsset(id);
                            return false;
                        });

                        $(parent).append($wrapper);
                        $wrapper.get(0);
                    },
                    customGetter: function(idPrefix, name, uniqueIndex) {
                        var id = [idPrefix, name, uniqueIndex].join('_');
                        return $.mtAppendGrid.getAsset(id);
                    },
                    customSetter: function(idPrefix, name, uniqueIndex, value) {
                        var id = [idPrefix, name, uniqueIndex].join('_');
                        $.mtAppendGrid.setAsset(id, value);
                    }
                };
            }
        },
        defaultOptions: {},
        forceOptions: {},
        translate: function(phrase) {
            return $.mtAppendGrid.i18n[phrase] || phrase;
        },
        selectAssetUrlBase: '',
        i18n: {}
    };

    $.widget('mt.widgetAppendGrid', {
        defaults: {
            initRows: 3,
            rowDragging: true,
            hideButtons: { moveUp: true, moveDown: true },
            i18n: $.mtAppendGrid.i18n,
            afterRowDragged: function(tbWhole, tbRowIndex) {
                if ( $.mtAppendGrid.afterRowDraggedCallbacks ) {
                    $.each($.mtAppendGrid.afterRowDraggedCallbacks, function(i, c) {
                        c();
                    });
                }
            }
        },
        _init: function(options) {
            var opts = $.extend(this.defaults, $.mtAppendGrid.defaultOptions, this.options, $.mtAppendGrid.forceOptions),
                grid = this,
                $grid = $(this.element);

            grid.opts = opts;

            grid.jqContainer = $grid;
            grid.jqValuesWrapper = $grid.find('.append-grid-values-wrapper');
            grid.jqValues = $grid.find('.append-grid-values');
            grid.jqTable = $grid.find('.append-grid-table');

            grid.jqControll = $grid.find('.append-grid-controll')
            grid.jqShowJson = $grid.find('.append-grid-show-json')
            grid.jqHideJson = $grid.find('.append-grid-hide-json')
            grid.jqGetJson = $grid.find('.append-grid-get-json')
            grid.jqSetJson = $grid.find('.append-grid-set-json')
            grid.jqParentForm = $grid.closest('form')

            grid.setUp();

            // var values = grid.parseValues(grid.jqValues.val());
            // grid.setValues(values);

            grid.jqShowJson.click(function() {
                grid.setStatus('json')
                return false;
            });

            grid.jqHideJson.click(function() {
                grid.setStatus('live');
                return false;
            });

            grid.jqGetJson.click(function() {
                grid.gridToJson();
                return false;
            });

            grid.jqSetJson.click(function() {
                grid.jsonToGrid();
                return false;
            });

            grid.jqParentForm.submit(function() {
                grid.gridToJson();
                grid.tearDown();
                return true;
            });
        },
        setStatus: function(status) {
            if ( status == 'json' ) {
                this.jqContainer.removeClass('append-grid-mode-live').addClass('append-grid-mode-json');
            } else { // stauts == 'live'
                this.jqContainer.addClass('append-grid-mode-live').removeClass('append-grid-mode-json');
            }
        },
        gridToJson: function() {
            var values = this.jqGrid.appendGrid('getAllValue');
            var json = this.stringifyValues(values);

            this.jqValues.val(json);
        },
        jsonToGridArray: function(json) {
            var data = this.parseValues(json, []);
            if ( !data || !data instanceof Array ) { data = []; }
            return data;
        },
        jsonToGrid: function() {
            var json = this.jqValues.val();
            var values = this.jsonToGridArray(json);
            this.jqGrid.appendGrid('load', values);
        },
        parseValues: function(json, _default) {
            var values = _default;
            try {
                values = JSON.parse(json);
            } catch(ex) {}

            if ( typeof values == 'string' ) {
                values = JSON.parse(values);
            }

            return values;
        },
        stringifyValues: function(values) {
            var json = $.mtAppendGrid.stringify(values);
            try {
                var str = JSON.parse(json);
                if ( typeof str == 'string' ) { json = str; }
            } catch (ex) {}

            return json;
        },
        setUp: function() {
            var opts = this.opts;

            // Columns
            opts.columns = opts.columns || []
            $.each(this.opts.columns, function(i, col) {
                var typer = col.type ? $.mtAppendGrid.customTypes[col.type] : undefined;
                var typed = typer ? typer(opts) : {};
                opts.columns[i] = $.extend(col, typed);
            });

            // Data
            var value = this.jqValues ? this.jqValues.val() : '';
            opts.initData = this.jsonToGridArray(value);

            // Build options
            this.jqGrid = this.jqTable.appendGrid(opts);

            return this.jqGrid;
        },
        tearDown: function() {

        }
    });
})(jQuery);
