if(!window.Bodo){ // namespace
    Bodo = new Object();
}

Bodo.Map = OpenLayers.Class(OpenLayers.Map, {

    options: {

        div: 'map',

        theme: null,

        projection: new OpenLayers.Projection('EPSG:2056'),

        displayProjection: new OpenLayers.Projection('EPSG:2056'),

        maxExtent: new OpenLayers.Bounds('2590000', '1210000', '2645000', '1265000'),

        units: 'm',

        maxResolution: 100.0,

        numZoomLevels: 10,

        controls: [
            new OpenLayers.Control.PanZoom(),
            new OpenLayers.Control.Navigation()
        ],

        layers: [
            new OpenLayers.Layer.WMS('Übersichtsplan', 'http://www.sogis1.so.ch/cgi-bin/sogis/sogis_bpav.wms', 
                {layers: 'bpav5000f'}
            ),
            new OpenLayers.Layer.WMS('Amtliche Vermessung', 'http://www.sogis1.so.ch/wms/grundbuchplan', 
                {layers: 'Amtliche Vermessung (schwarz-weiss)'}, 
                {isBaseLayer: false, opacity: 0.5}
            ) 
        ]
    },

    standortLayer:  new OpenLayers.Layer.Vector('Standort'),

    initialize: function(div, options) {

        OpenLayers.Util.extend(this.options, options);
        OpenLayers.Map.prototype.initialize.apply(this, [this.options]);

        this.addLayer(this.standortLayer);

    },

    addGeometry: function(geometry) {

        var geometry = new OpenLayers.Format.WKT().read(geometry);
        this.standortLayer.addFeatures([geometry]);
    },

    editGeometry: function(x_formfield_id, y_formfield_id) {

        $(x_formfield_id + ',' + y_formfield_id)
            .data('map', this)
            .change(function(event) {
                var geometry = new OpenLayers.Geometry.Point($(x_formfield_id).val(), $(y_formfield_id).val());
                if (geometry) {
                    var feature = new OpenLayers.Feature.Vector(geometry);
                    $(event.target).data('map').standortLayer.addFeatures([feature]);
                }
            }).trigger('change');

        if ($(x_formfield_id).val() && $(y_formfield_id).val()) {
            this.setCenter(this.standortLayer.getDataExtent().getCenterLonLat(), 7);
        } else {
            this.zoomToMaxExtent();
        }

        this.addControl(new Bodo.EditingToolbar(this.standortLayer));
        this.standortLayer.events.register('beforefeatureadded', this, function(feature) {
            this.standortLayer.removeAllFeatures();
            $(x_formfield_id).val(feature.feature.geometry.x);
            $(y_formfield_id).val(feature.feature.geometry.y);
        });

    }
});

Bodo.initializeGrid = function(prefix) {

    var template = $('#'+prefix+'-template tbody').html();
    var count = $('#'+prefix+'-table tbody tr').length-1;
    var remove = function(event){
        $(event.target).closest('tr').hide().find('input[name*="delete"]').val('1');
    }

    // Add new row to table of Schichten.
    $('#'+prefix+'-add').click(function() {
        $('#'+prefix+'-table tbody').append(template)
            .find('tr:last input, tr:last select').each(function(index, field) {
                $(field).attr('name', $(field).attr('name').replace('[]', '['+count+']'));
            });
        $('#'+prefix+'-table .'+prefix+'-remove:last').click(remove);
        count++;
        return false;
    });

    // Remove row from table of Schichten.
    $('.'+prefix+'-remove').click(remove);

    $('#'+prefix+'-table tbody tr').each(function(index, row) {
        if ($(row).find('input[name*="delete"]').val()) {
            $(row).hide();
        }
    });
}


Bodo.EditingToolbar = OpenLayers.Class(
  OpenLayers.Control.Panel, {

    /**
     * Constructor: OpenLayers.Control.EditingToolbar
     * Create an editing toolbar for a given layer.
     *
     * Parameters:
     * layer - {<OpenLayers.Layer.Vector>}
     * options - {Object}
     */
    initialize: function(layer, options) {
        OpenLayers.Control.Panel.prototype.initialize.apply(this, [options]);

        this.addControls(
          [ new OpenLayers.Control.Navigation() ]
        );
        var controls = [
          new OpenLayers.Control.DrawFeature(layer, OpenLayers.Handler.Point, {'displayClass': 'olControlDrawFeaturePoint'})
        ];
        this.addControls(controls);
    },

    /**
     * Method: draw
     * calls the default draw, and then activates mouse defaults.
     *
     * Returns:
     * {DOMElement}
     */
    draw: function() {
        var div = OpenLayers.Control.Panel.prototype.draw.apply(this, arguments);
        if (this.defaultControl === null) {
            this.defaultControl = this.controls[0];
        }
        return div;
    },

    CLASS_NAME: "OpenLayers.Control.EditingToolbar"
});
