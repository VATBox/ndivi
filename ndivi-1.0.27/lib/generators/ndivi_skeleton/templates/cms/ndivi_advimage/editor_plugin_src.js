/**
 * editor_plugin_src.js
 *
 * Copyright 2009, Moxiecode Systems AB
 * Released under LGPL License.
 *
 * License: http://tinymce.moxiecode.com/license
 * Contributing: http://tinymce.moxiecode.com/contributing
 */

(function() {
	tinymce.create('tinymce.plugins.NdiviAdvancedImagePlugin', {
		init : function(ed, url) {
			// Register commands
			ed.addCommand('mceNdiviAdvImage', function() {
				// Internal image object like a flash placeholder
				if (ed.dom.getAttrib(ed.selection.getNode(), 'class', '').indexOf('mceItem') != -1)
					return;

				ed.windowManager.open({
					file : url + '/image.htm',
					width : 480 + parseInt(ed.getLang('ndivi_advimage.delta_width', 0)),
					height : 385 + parseInt(ed.getLang('ndivi_advimage.delta_height', 0)),
					inline : 1
				}, {
					plugin_url : url
				});
			});

			// Register buttons
			ed.addButton('image', {
				title : 'ndivi_advimage.image_desc',
				cmd : 'mceNdiviAdvImage'
			});
		},

		getInfo : function() {
			return {
				longname : 'Ndivi Advanced image',
				author : 'Ndivi Ltd.',
				authorurl : 'http://ndivi.com',
				version : tinymce.majorVersion + "." + tinymce.minorVersion
			};
		}
	});

	// Register plugin
	tinymce.PluginManager.add('ndivi_advimage', tinymce.plugins.NdiviAdvancedImagePlugin);
})();
