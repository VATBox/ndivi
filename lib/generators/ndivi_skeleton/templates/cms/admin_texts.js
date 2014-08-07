function select_texts_branch() {
  var branch_root = $('select#branch').val();
  $('#texts .text').hide();
  $('#texts .text_' + branch_root).show();   
  $('input.branch').val(branch_root);   
} 

$(document).ready(function() {
  var tinymce_settings = {
      script_url : '/javascripts/tinymce_jquery/tiny_mce.js',
      theme : "advanced",
      forced_root_block : '',        
      relative_urls : false,
      convert_urls: false,  
      theme_advanced_buttons1 : "bold,italic,underline,forecolor,backcolor,image,formatselect,code",
      theme_advanced_buttons2 : "",
      theme_advanced_buttons3 : "",
      theme_advanced_toolbar_location : "bottom",
      theme_advanced_toolbar_align : "left",
      theme_advanced_statusbar_location : "",
      theme_advanced_resizing : false,
      valid_elements: "h1,h2,h3,h4,h5,a[href|title],blockquote[cite],span[style],br,caption,cite,code,dl,dt,dd,em,i,img[src|alt|title|width|height|align],li,ol,p,pre,q[cite],small,strike,strong/b,sub,sup,u,ul",    
      gecko_spellcheck: true,
      plugins: "advimage,paste",
      forced_root_block: false, 
      force_br_newlines: true,
      force_p_newlines: false, 
      remove_linebreaks: false,
      paste_convert_middot_lists: true,
      directionality: $('#selected_locale').val() == 'he' ? 'rtl' : 'ltr',
      dialog_type: "window"
  };

  $('select#branch').change(select_texts_branch);
  select_texts_branch();

  $('#texts td.locale').click(function() {
    if ($(this).data('expanded')) {
      return true;
    }     
    var locale_part = $(this);
    var text_elem = $(locale_part).find('.text_editor')[0];
    $(locale_part).data('original_value', $(text_elem).val());
    
    $(locale_part).find('.editing').show();
    
    $(this).data('expanded', true);
    $(locale_part).addClass('expanded');
    return false;     
  });

  $('#texts td.locale .rich_text_mode').click(function() {
    var locale_part = $(this).parents('.locale');
    var text_elem = $(locale_part).find('.text_editor');
    text_elem.tinymce(tinymce_settings);
    $(this).hide();
    $(locale_part).find('.plain_text_mode').show();   
    return false;
  });

  $('#texts td.locale .plain_text_mode').click(function() {
    var locale_part = $(this).parents('.locale');
    var text_elem = $(locale_part).find('.text_editor');
    text_elem.tinymce().remove();
    $(this).hide();
    $(locale_part).find('.rich_text_mode').show();    
    return false;
  });

  function close_text_editor(locale_part) {
    var text_elem = $(locale_part).find('.text_editor');
    if (typeof(tinyMCE) !== 'undefined' && text_elem.tinymce()) text_elem.tinymce().remove();
    $(locale_part).find('.editing').hide();      
    $(locale_part).data('expanded', false);      
    $(locale_part).removeClass('expanded');
    $(locale_part).find('.rich_text_mode').show();        
    $(locale_part).find('.plain_text_mode').hide();       
  }
  
  $('#texts .actions .cancel').live('click', function() {
    var locale_part = $(this).parents('.locale');
    close_text_editor(locale_part);
    $(locale_part).find('.text_editor').val($(locale_part).data('original_value'));
    return false;            
  });

  $('#texts .actions .save').live('click', function() {
    var locale_part = $(this).parents('.locale');
    var content = $(locale_part).find('.text_editor').val();
    if (content.substr(-6) == "<br />") {
      content = content.substr(0, content.length - 6);
    }     
    close_text_editor(locale_part);
    var original_content = $(locale_part).data('original_value');
    if (original_content == content) {
      return;
    }
    $(locale_part).find('.html_content').html('<img src="/images/spinner.gif"/>');        
    $.ajax({
      url: '/admin/texts',
      type: 'POST',
      data: {
        _method: 'PUT',
        key: $(locale_part).parents('.text').attr('data-key'),
        locale: $(locale_part).attr('data-locale'),
        value: content
      },
      dataType: "json",
      success: function(data) {
        $(locale_part).find('.html_content').html(data.truncated_text);
        $(locale_part).parents('.text').addClass('modified');
      }
    });      
  });

});            
