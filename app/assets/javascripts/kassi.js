// Custom Javascript functions for Sharetribe
// Add custom validation methods
function add_validator_methods() {
  
  // If some element is required, it should be validated even if it's hidden
  $.validator.setDefaults({ ignore: [] });
  
  $.validator.
  	addMethod("accept",
  		function(value, element, param) {
  			return value.match(new RegExp(/(\.jpe?g|\.gif|\.png|^$)/i));
  		}
  	);

  $.validator.
  	addMethod( "valid_username", 
  		function(value, element, param) {
  			return value.match(new RegExp("(^[A-Za-z0-9_]*$)"));
  		}
  	);
  
  $.validator.
    addMethod("regex",
      function(value, element, regexp) {
        var re = new RegExp(regexp);
        return re.test(value);
      }
  );
  $.validator.
    addMethod("email_list",
      function(value, element, param) {
        var emails = value.split(',');
        var re = new RegExp(/^([\w\.\-]+)@([\w\-]+)((\.(\w){2,6})+)$/i);
        for (var i = 0; i < emails.length; i++) {
          console.log(emails[i]);
          if (!re.test($.trim(emails[i]))) {
            console.log(emails[i] + "was not ok?");
            return false; 
          } 
        }
        return true;
      }
  );

  $.validator.	
  	addMethod("min_date", 
  		function(value, element, is_rideshare) {
  			if (is_rideshare == "true") {
  				return get_datetime_from_datetime_select() > new Date();
  			} else {
  				return get_date_from_date_select() > new Date();
  			}
  	 	}
  	);

  $.validator.	
  	addMethod("max_date", 
  		function(value, element, is_rideshare) {
  			var current_time = new Date();
  			maximum_date = new Date((current_time.getFullYear() + 1),current_time.getMonth(),current_time.getDate(),0,0,0);
  			if (is_rideshare == "true") {
  				return get_datetime_from_datetime_select() < maximum_date;
  			} else {
  				return get_date_from_date_select() < maximum_date;
  			}
  	 	}
  	);	

  $.validator.
    addMethod( "captcha", 
    	function(value, element, param) {	  
    	  challengeField = $("input#recaptcha_challenge_field").val();
        responseField = $("input#recaptcha_response_field").val();

        var resp = $.ajax({
              type: "GET",
              url: "signup/check_captcha",
              data: "recaptcha_challenge_field=" + challengeField + "&amp;recaptcha_response_field=" + responseField,
              async: false
        }).responseText;

        if (resp == "success") {
          return true;
        } else {
          Recaptcha.reload();
          return false;
        }
      }
    );

  $.validator.	
  	addMethod("required_when_not_neutral_feedback", 
  		function(value, element, param) {
  			if (value == "") {
  				var radioButtonArray = new Array("1", "2", "4", "5"); 
  				for (var i = 0; i < radioButtonArray.length; i++) {
  				  if ($('#grade-' + radioButtonArray[i]).is(':checked')) {
  						return false;
  					}
  				}
  			}
  			return true; 
  	 	}
  	);

}

// Initialize code that is needed for every view
function initialize_defaults(locale) {
  add_validator_methods();
  translate_validation_messages(locale);
  setTimeout(hideNotice, 5000);
  $('.flash-notifications').click(function() {
    $('.flash-notifications').fadeOut('slow');
  });
  $('#login-toggle-button').click(function() { 
    $('#upper_person_login').focus();
  });
}

var hideNotice = function() {
  $('.flash-notifications').fadeOut('slow');
}

function initialize_user_feedback_form() {
  form_id = "#new_feedback"
  $(form_id).validate({
    rules: {
      "feedback[email]": {required: false, email: true},
			"feedback[content]": {required: true, minlength: 1}
		}
	});
}

function initialize_email_members_form() {
  form_id = "#new_member_email"
  $(form_id).validate({
    rules: {
      "email[title]": {required: false, email: true},
			"email[content]": {required: true, minlength: 1}
		}
	});
}

function initialize_feedback_tab() {
  $('.feedback_div').tabSlideOut({
  	tabHandle: '.handle',                     //class of the element that will become your tab
    pathToTabImage: '/assets/feedback_handles.png',
	  imageHeight: '122px',                     //height of tab image           //Optionally can be set using css
    imageWidth: '40px',                       //width of tab image            //Optionally can be set using css
    tabLocation: 'left',                      //side of screen where tab lives, top, right, bottom, or left
    speed: 300,                               //speed of animation
    action: 'click',                          //options: 'click' or 'hover', action to trigger animation
   	topPos: '200px',                          //position from the top/ use if tabLocation is left or right
    fixedPosition: true
  });
}

function initialize_login_form(password_forgotten) {
  if (password_forgotten == true) {
    $('#password_forgotten').slideDown('fast');
		$("html, body").animate({ scrollTop: $(document).height() }, 1000);
		$('input.request_password').focus();
  }
	$('#password_forgotten_link').click(function() { 
		$('#password_forgotten').slideToggle('fast');
		$("html, body").animate({ scrollTop: $(document).height() }, 1000);
		$('input.request_password').focus();
	});
  $('#login_form input.text_field:first').focus();
}

function reload_selected_links(locale, link) {
  
  $('.option-group').addClass('hidden');
  link.addClass('hidden');
  $('.share-type-option').each(function(index) { 
    $(this).addClass('hidden'); 
  });
  $('.form-fields').addClass('hidden');
  if (link.parent().hasClass('listing_type')) {
    $('.category').children().addClass('hidden');
    $('.subcategory').children().addClass('hidden');
    $('.share_type').children().addClass('hidden');
    $('.option-group-title').addClass('hidden');
  } else if (link.parent().hasClass('category')) {
    $('.subcategory').children().addClass('hidden');
    $('.share_type').children().addClass('hidden');
    $('.group-options-title').addClass('hidden');
    $('.option-group-title.subcategory').addClass('hidden');
  } else if (link.parent().hasClass('subcategory')) {
    $('.share_type').children().addClass('hidden');
    $('.group-options-title').addClass('hidden');
  }
  display_option_links(link.parent().attr('class'));
  
}

// Make changes based on a click in a "selected" link in the listing form
function display_option_links(section_name) {
  $('.' + section_name + '-options').removeClass('hidden');
  // Make sure that only the correct share types are displayed.
  if (section_name == "share_type") {
    listing_type = $('.listing_type').children().not('.hidden').attr('name');
    category = $('.category').children().not('.hidden').attr('name');
    $('.share-type-option').each(function(index) {
      if ($(this).hasClass(listing_type) && $(this).hasClass(category)) {
        $(this).removeClass('hidden');
      }
    });
  }
}

// Load new listing form with AJAX
function display_form_fields(sections, locale) {
  $('.form-fields').removeClass('hidden');
  var new_listing_path = '/' + locale + '/listings/new';
  var params = {};
  
  for (var j = 0; j < sections.length; j++) {
    params[sections[j]] = $('.' + sections[j]).children().not('.hidden').attr('name');
  }
  
  $.get(new_listing_path, params, function(data) {
    $('.form-fields').html(data);
  });
}

// Make changes based on a click in an "option" link in the listing form
function reload_option_links(locale, link, valid_share_types) {
  
  var sections = ["listing_type", "category", "share_type"];
  // Use this instead if subcategories are used
  // var sections = ["listing_type", "category", "subcategory", "share_type"];
  
  $('.selected[name=' + link.attr('name') + ']').removeClass('hidden');
  
  for (var i = 0; i < sections.length; i++) {
    listing_type = $('.listing_type').children().not('.hidden').attr('name');
    if (link.parent().hasClass(sections[i] + '-options')) {
      $('.' + sections[i] + '-options').addClass('hidden');
      if (i == (sections.length - 1)) {
        // If this is the last selection before displaying the form,
        // prepare the form parameters and make the ajax call
        display_form_fields(sections, locale);
      } else {
        // If the last section would be share types, but there are no share types
        // for this category, display form instead of the section. Otherwise,
        // display the next section normally.
        if (sections[i + 1] == "share_type") {
          category = $('.category').children().not('.hidden').attr('name');
          if (valid_share_types[listing_type][category] == null) {
             display_form_fields(sections, locale);
           } else {
             $('.option-group-title.share_type.' + listing_type).removeClass('hidden');
             display_option_links(sections[i + 1]);
           }
        } else {
          // Display correct titles in category and subcategory form depending on
          // previous selections
          if (sections[i + 1] == "category") {
            $('.option-group-title.category.' + listing_type).removeClass('hidden');
          } else if (sections[i + 1] == "subcategory") {
            category = $('.category').children().not('.hidden').attr('name');
            $('.option-group-title.subcategory.' + category).removeClass('hidden');
          }
          display_option_links(sections[i + 1]);
        }
      }
      return;
    }
  }

}

// Initialize the listing type & category selection part of the form
function initialize_new_listing_form_selectors(locale, valid_share_types) {
  
  $('.new-listing-form').find('a.selected').click(
    function() {
      reload_selected_links(locale, $(this));
    }
  );
  
  $('.new-listing-form').find('a.option').click(
    function() {
      reload_option_links(locale, $(this), valid_share_types);
    }
  );
  
}

// Initialize the actual form fields
function initialize_new_listing_form(fileDefaultText, fileBtnText, locale, share_type_message, date_message, is_rideshare, is_offer, listing_id, address_validator) {
  $('#help_valid_until_link').click(function() { $('#help_valid_until').lightbox_me({centered: true, zIndex: 1000000}); });
	$('input.title_text_field:first').focus();
	
	$(':radio[name=valid_until_select]').change(function() {
		if ($(this).val() == "for_now") {
			$('select.listing_datetime_select').attr('disabled', 'disabled');
		} else {
			$('select.listing_datetime_select').removeAttr('disabled');
		}
	});
	
	form_id = (listing_id == "false") ? "#new_listing" : ("#edit_listing_" + listing_id);
	
	// Change the origin and destination requirements based on listing_type
	var rs = null;
	if (is_rideshare == "true") {
		rs = true;
	} else {
		rs = false;
	}
	
	$(form_id).validate({
		errorPlacement: function(error, element) {
			if (element.attr("name") == "listing[listing_images_attributes][0][image]")	{
				error.appendTo(element.parent());
			} else if (element.attr("name") == "listing[valid_until(1i)]") {
				error.appendTo(element.parent());
			} else {
				error.insertAfter(element);
			}
		},
		debug: false,
		rules: {
			"listing[title]": {required: true},
			"listing[origin]": {required: rs, address_validator: true},
			"listing[destination]": {required: rs, address_validator: true},
			"listing[listing_images_attributes][0][image]": { accept: "(jpe?g|gif|png)" },
			"listing[valid_until(1i)]": { min_date: is_rideshare, max_date: is_rideshare }
		},
		messages: {
			"listing[valid_until(1i)]": { min_date: date_message, max_date: date_message },
			"listing[origin]": { address_validator: "Ei osoitetta" }
		},
		// Run validations only when submitting the form.
		onkeyup: false,
    onclick: false,
    onfocusout: false,
		onsubmit: true,
		submitHandler: function(form) {
		  disable_and_submit(form_id, form, "false", locale);
		}
	});
	
	set_textarea_maxlength();
	auto_resize_text_areas("listing_description_textarea");
}

function initialize_send_message_form(locale) {
	auto_resize_text_areas("text_area");
	$('textarea').focus();
	var form_id = "#new_conversation";
	$(form_id).validate({
		rules: {
		  "conversation[title]": {required: true, minlength: 1, maxlength: 120},
			"conversation[message_attributes][content]": {required: true, minlength: 1}
		},
		submitHandler: function(form) {
		  disable_and_submit(form_id, form, "false", locale);
		}
	});	
}

function initialize_reply_form(locale) {
	auto_resize_text_areas("reply_form_text_area");
	$('textarea').focus();
	prepare_ajax_form(
    "#new_message",
    locale, 
    {"message[content]": {required: true, minlength: 1}}
  );
}

function initialize_listing_view(locale) {
  $('#listing-image-link').click(function() { $('#listing-image-lightbox').lightbox_me({centered: true, zIndex: 1000000}); });
	auto_resize_text_areas("listing_comment_content_text_area");
	prepare_ajax_form(
    "#new_comment",
    locale, 
    {"comment[content]": {required: true, minlength: 1}}
  );
}

function initialize_give_feedback_form(locale, grade_error_message, text_error_message) {
	auto_resize_text_areas("text_area");
	$('textarea').focus();
	style_grade_selectors();
	var form_id = "#new_testimonial";
	$(form_id).validate({
		errorPlacement: function(error, element) {
			if (element.attr("name") == "testimonial[grade]") {
				error.appendTo(element.parent().parent());
			}	else {
			  error.insertAfter(element);
			}
		},	
		rules: {
			"testimonial[grade]": {required: true},
			"testimonial[text]": {required: true}
		}, 
		messages: {
			"testimonial[grade]": { required: grade_error_message }
		},
		submitHandler: function(form) {
		  disable_and_submit(form_id, form, "false", locale);
		}
	});
}

function style_grade_selectors() {
  $(".feedback-grade").each(function() {
    $(this).find('label').hide();
    $(this).find('.grade').each(
      function() {
        $(this).removeClass('hidden');
        $(this).click(
          function() {
            $(this).siblings().removeClass('negative').removeClass('positive');
            $(this).addClass($(this).attr('id'));
            $(".feedback-grade").find('input:radio[id=' + $(this).attr('name') + ']').attr('checked', true);
          }
        );
      }  
    );
  });
}



function initialize_signup_form(locale, username_in_use_message, invalid_username_message, email_in_use_message, captcha_message, invalid_invitation_code_message, name_required, invitation_required) {
	$('#help_invitation_code_link').click(function(link) {
	  //link.preventDefault();
	  $('#help_invitation_code').lightbox_me({centered: true, zIndex: 1000000 }); 
	});
	$('#terms_link').click(function(link) {
	  link.preventDefault();
	  $('#terms').lightbox_me({ centered: true, zIndex: 1000000 }); 
	});
	var form_id = "#new_person";
	//name_required = (name_required == 1) ? true : false
	$(form_id).validate({
		errorPlacement: function(error, element) {
			if (element.attr("name") == "person[terms]") {
				error.appendTo(element.parent().parent());
			} else if (element.attr("name") == "recaptcha_response_field") {
			  error.appendTo(element.parent().parent().parent().parent().parent().parent().parent().parent().parent());
			} else {
				error.insertAfter(element);
			}	
		},
		rules: {
      "person[username]": {required: true, minlength: 3, maxlength: 20, valid_username: true, remote: "/people/check_username_availability"},
      "person[given_name]": {required: name_required, maxlength: 30},
      "person[family_name]": {required: name_required, maxlength: 30},
      "person[email]": {required: true, email: true, remote: "/people/check_email_availability_and_validity"},
      "person[terms]": "required",
      "person[password]": { required: true, minlength: 4 },
      "person[password2]": { required: true, minlength: 4, equalTo: "#person_password1" },
			"recaptcha_response_field": {required: true, captcha: true },
			"invitation_code": {required: invitation_required, remote: "/people/check_invitation_code"}
		},
		messages: {
		  "recaptcha_response_field": { captcha: captcha_message },
			"person[username]": { valid_username: invalid_username_message, remote: username_in_use_message },
			"person[email]": { remote: email_in_use_message },
			"invitation_code": { remote: invalid_invitation_code_message }
		},
		onkeyup: false, //Only do validations when form focus changes to avoid exessive ASI calls
		submitHandler: function(form) {
      disable_and_submit(form_id, form, "false", locale);  
		}
	});	
}

function initialize_terms_form() {
	$('#terms_link').click(function(link) {
	  link.preventDefault();
	  $('#terms').lightbox_me({ centered: true, zIndex: 1000000 }); 
	});
}

function initialize_update_profile_info_form(locale, person_id, address_validator, name_required) {
	auto_resize_text_areas("update_profile_description_text_area");
	$('input.text_field:first').focus();
	var form_id = "#edit_person_" + person_id;
	$(form_id).validate({
		rules: {
      "person[street_address]": {required: false, address_validator: true},
			"person[given_name]": {required: name_required, maxlength: 30},
      "person[family_name]": {required: name_required, maxlength: 30},
			"person[phone_number]": {required: false, maxlength: 25}
		},
		 onkeyup: false,
         onclick: false,
         onfocusout: false,
		 onsubmit: true,
		submitHandler: function(form) {
		  disable_and_submit(form_id, form, "false", locale);
		}
	});	
}

function initialize_update_notification_settings_form(locale, person_id) {
	var form_id = "#edit_person_" + person_id;
	$(form_id).validate({
		submitHandler: function(form) {
		  disable_and_submit(form_id, form, "false", locale);
		}
	});	
}

function initialize_update_avatar_form(fileDefaultText, fileBtnText, locale) {
	var form_id = "#avatar_form";
	$(form_id).validate({
		rules: {
			"person[image]": { accept: "(jpe?g|gif|png)" } 
		},
		submitHandler: function(form) {
		  disable_and_submit(form_id, form, "false", locale);
		}
	});	
}

function initialize_update_account_info_form(locale, change_text, cancel_text, email_in_use_message) {
	$('#account_email_link').toggle(
		function() {
			$('#account_email_form').show();
			$(this).text(cancel_text);
			$('#person_email').focus();
		},
		function() {
			$('#account_email_form').hide();
			$(this).text(change_text);
		}
	);
	$('#account_password_link').toggle(
		function() {
			$('#account_password_form').show();
			$(this).text(cancel_text);
			$('#person_password').focus();
		},
		function() {
			$('#account_password_form').hide();
			$(this).text(change_text);
		}
	);
	var email_form_id = "#email_form";
	$(email_form_id).validate({
		rules: {
			"person[email]": {required: true, email: true, remote: "/people/check_email_availability"}
		},
		messages: {
			"person[email]": { remote: email_in_use_message }
		},
		submitHandler: function(form) {
		  disable_and_submit(email_form_id, form, "false", locale);
		}
	});
	var password_form_id = "#password_form";
	$(password_form_id).validate({
		rules: {
			"person[password]": { required: true, minlength: 4 },
			"person[password2]": { required: true, minlength: 4, equalTo: "#person_password" }
		},
		submitHandler: function(form) {
		  disable_and_submit(password_form_id, form, "false", locale);
		}
	});	
}

function initialize_reset_password_form() {
	var password_form_id = "#new_person";
	$(password_form_id).validate({
		errorPlacement: function(error, element) {
			error.insertAfter(element);
		},
		rules: {
			"person[password]": { required: true, minlength: 4 },
			"person[password_confirmation]": { required: true, minlength: 4, equalTo: "#person_password" }
		},
		submitHandler: function(form) {
		  disable_and_submit(password_form_id, form, "false", locale);
		}
	});	
}

function initialize_profile_view(badges, profile_id) {
	$('#load-more-listings').click(function() { 
	  request_path = profile_id + "/listings";
	  $.get(request_path, function(data) {
      $('#profile-listings-list').html(data);
    });
    return false;
  });
	
	$('#load-more-testimonials').click(function() { 
	  request_path = profile_id + "/testimonials";
	  $.get(request_path, {per_page: 200, page: 1}, function(data) {
      $('#profile-testimonials-list').html(data);
    });
    return false;
  });
	
	
	// The code below is not used in early 3.0 version, but part of it will probably be used again soon, so kept here.
	$('#description_preview_link').click(function() { 
		$('#profile_description_preview').hide();
		$('#profile_description_full').show(); 
	});
	$('#description_full_link').click(function() { 
		$('#profile_description_preview').show();
		$('#profile_description_full').hide(); 
	});
	$('#badges_description_link').click(function() { $('#badges_description').lightbox_me({centered: true}); });
	$('#trustcloud_description_link').click(function() { $('#trustcloud_description').lightbox_me({centered: true}); });
	for (var i = 0; i < badges.length; i++) {
		$('#' + badges[i] + '_description_link').click(function(badge) {
		  badge.preventDefault();
			$('#' + badge.currentTarget.id + '_target').lightbox_me({centered: true});
		});
	}
}

function initialize_homepage_news_items(news_item_ids) {
  for (var i = 0; i < news_item_ids.length; i++) {
    $('#news_item_' + news_item_ids[i] + '_content').click(function(news_item) {
      $('#' + news_item.currentTarget.id + '_div_preview').hide();
      $('#' + news_item.currentTarget.id + '_div_full').show(); 
    });
    $('#news_item_' + news_item_ids[i] + '_content_div').click(function(news_item) { 
      $('#' + news_item.currentTarget.id + '_preview').show();
      $('#' + news_item.currentTarget.id + '_full').hide();
    });
  }
}

function initialize_homepage(filters_in_use) {
  
  if (filters_in_use) { 
    // keep filters dropdown open in mobile view if any filters selected
    $('#filters-toggle').click();
  }
  
  $('#feed-filter-dropdowns select').change(
    function() {
      
      // It's challenging to get the pageless right if reloading just the small part so reload all page
      // instead of the method below that would do AJAX update (currently works only partially)
      //reload_homepage_view();
      
      $("#homepage-filters").submit();    
      
    }
  );
  
  // make map/list button change the value in the filter form and submit the form
  // in order to keep all filter values combinable and remembered
  $('.map-button').click(
    function() {
      $("#hidden-map-toggle").val(true);
      $("#homepage-filters").submit();
      return false;
    }
  );
  $('.list-button').click(
    function() {
      $("#hidden-map-toggle").val(undefined);
      $("#homepage-filters").submit();
      return false;
    }
  );
}

function reload_homepage_view() {
  // Make AJAX request based on selected items
  var request_path = window.location.toString();
  var filters = {};
  filters["share_type"] = $('#share_type').val();
  filters["category"] = $('#listing_category').val();
  
  // Update request path with updated query params
  for (var key in filters) {
    request_path = UpdateQueryString(key, filters[key], request_path);
  }
  
  $.get(request_path, filters, function(data) {
    $('.homepage-feed').html(data);
    history.pushState(null, document.title, request_path);
  });
}

function initialize_invitation_form(locale, email_error_message) {
	$("#new_invitation").validate({
		rules: {
			"invitation[email]": {required: true, email_list: true},
			"invitation[message]": {required: false, maxlength: 5000}
		},
		messages: {
			"invitation[email]": { email_list: email_error_message}
		},
		submitHandler: function(form) {
		  disable_and_submit("#new_invitation", form, "false", locale);
		}
	});
}


function initialize_private_community_defaults(locale, feedback_default_text) {
  add_validator_methods();
  translate_validation_messages(locale);
  $('select.language_select').selectmenu({style: 'dropdown', width: "100px"});
  $('#close_notification_link').click(function() { $('#notifications').slideUp('fast'); });
	// Make sure that Sharetribe cannot be used if js is disabled
	$('.wrapper').addClass('js_enabled');
}

function initialize_private_community_homepage(username_or_email_default_text, password_default_text) {
  $('#password_forgotten_link').click(function() { 
		$('#password_forgotten').slideToggle('fast'); 
		$('input.request_password').focus();
	});
	$('#person_login').watermark(username_or_email_default_text, {className: 'default_text'});
	$('#person_password').watermark(password_default_text, {className: 'default_text'});
	$('.wrapper').addClass('js_enabled');
}	
	
function initialize_admin_news_item(news_item_id) {
  $('#news_item_' + news_item_id + '_content_link').click(function() { 
		$('#news_item_' + news_item_id + '_content').slideToggle('fast'); 
	});
}

function initialize_admin_new_news_item_form() {
  auto_resize_text_areas("new_news_item_text_area");
  $('#new_news_item input.text_field:first').focus();
  $('#new_news_item').validate({
		rules: {
		  "news_item[title]": {required: true, minlength: 1, maxlenght: 200},
		  "news_item[content]": {required: true, minlength: 1, maxlenght: 10000}
		}
	});
}

function initialize_admin_new_poll_form() {
  
}

function initialize_admin_edit_tribe_form(locale, community_id) {
  auto_resize_text_areas("new_tribe_text_area");
  translate_validation_messages(locale);
  $('#invite_only_help_text_link').click(function() { $('#invite_only_help_text').lightbox_me({centered: true}); });
  var form_id = "#edit_community_" + community_id;
  $(form_id).validate({
 		rules: {
 			"community[name]": {required: true, minlength: 2, maxlength: 50},
 			"community[slogan]": {required: true, minlength: 2, maxlength: 100},
 			"community[description]": {required: true, minlength: 2, maxlength: 500}
 		},
 		submitHandler: function(form) {
 		  disable_and_submit(form_id, form, "false", locale);
 		}
 	});
}

function initialize_admin_edit_tribe_look_and_feel_form(locale, community_id, invalid_color_code_message) {
  translate_validation_messages(locale);
  var form_id = "#edit_community_" + community_id;
  $(form_id).validate({
 		rules: {
 			"community[custom_color1]": {required: false, minlength: 6, maxlength: 6, regex: "^([a-fA-F0-9]+)?$"}
 		},
 		messages: {
			"community[custom_color1]": { regex: invalid_color_code_message }
		},
 		submitHandler: function(form) {
 		  disable_and_submit(form_id, form, "false", locale);
 		}
 	});
}

function initialize_new_community_membership_form(email_invalid_message, invitation_required, invalid_invitation_code_message) {
  $('#help_invitation_code_link').click(function(link) {
	  $('#help_invitation_code').lightbox_me({centered: true, zIndex: 1000000 }); 
	});
  $('#terms_link').click(function(link) {
	  link.preventDefault();
	  $('#terms').lightbox_me({ centered: true, zIndex: 1000000 }); 
	});
  $('#new_community_membership').validate({
    errorPlacement: function(error, element) {
			if (element.attr("name") == "community_membership[consent]") {
				error.appendTo(element.parent().parent());
			} else {
			  error.insertAfter(element);
			}
		},
		rules: {
		  "community_membership[email]": {required: true, email: true, remote: "/people/check_email_validity"},
		  "community_membership[consent]": {required: true},
		  "invitation_code": {required: invitation_required, remote: "/people/check_invitation_code"}
		},
		messages: {
			"community_membership[email]": { remote: email_invalid_message },
			"invitation_code": { remote: invalid_invitation_code_message }
		},
	});	  
}

function set_textarea_maxlength() {
  var ignore = [8,9,13,33,34,35,36,37,38,39,40,46];
  var eventName = 'keypress';
  $('textarea[maxlength]')
    .live(eventName, function(event) {
      var self = $(this),
          maxlength = self.attr('maxlength'),
          code = $.data(this, 'keycode');
      if (maxlength && maxlength > 0) {
        return ( self.val().length < maxlength
                 || $.inArray(code, ignore) !== -1 );
 
      }
    })
    .live('keydown', function(event) {
      $.data(this, 'keycode', event.keyCode || event.which);
    });
}

// Return listing categories
function categories() {
	return ["item", "favor", "rideshare", "housing"];
}

function get_date_from_date_select() {
	year = $('#listing_valid_until_1i').val();
	month = $('#listing_valid_until_2i').val();
	day = $('#listing_valid_until_3i').val();
	date = new Date(year,month-1,day,"23","59","58");
	return date;
}

function get_datetime_from_datetime_select() {
	year = $('#listing_valid_until_1i').val();
	month = $('#listing_valid_until_2i').val();
	day = $('#listing_valid_until_3i').val();
 	hours= $('#listing_valid_until_4i').val();
	minutes = $('#listing_valid_until_5i').val();
	date = new Date(year,month-1,day,hours,minutes);
	return date;
}

// Credits to ellemayo's StackOverflow answer: http://stackoverflow.com/a/11654596/150382
function UpdateQueryString(key, value, url) {
    if (!url) url = window.location.href;
    var re = new RegExp("([?|&])" + key + "=.*?(&|#|$)", "gi");

    if (url.match(re)) {
        if (value)
            return url.replace(re, '$1' + key + "=" + value + '$2');
        else
            return url.replace(re, '$2');
    }
    else {
        if (value) {
            var separator = url.indexOf('?') !== -1 ? '&' : '?',
                hash = url.split('#');
            url = hash[0] + separator + key + '=' + value;
            if (hash[1]) url += '#' + hash[1];
            return url;
        }
        else
            return url;
    }
}

//FB Popup from: http://stackoverflow.com/questions/4491433/turn-omniauth-facebook-login-into-a-popup
// Didn't work now, but I leave here to make things faster if want to invesetigate more.

// function popupCenter(url, width, height, name) {
//   var left = (screen.width/2)-(width/2);
//   var top = (screen.height/2)-(height/2);
//   return window.open(url, name, "menubar=no,toolbar=no,status=no,width="+width+",height="+height+",toolbar=no,left="+left+",top="+top);
// }
// 
// $("a.popup").click(function(e) {
//   alert("HOE");
//   popupCenter($(this).attr("href"), $(this).attr("data-width"), $(this).attr("data-height"), "authPopup");
//   e.stopPropagation(); return false;
// });

function closeAllToggleMenus() {
  $('.toggle-menu').addClass('hidden');
  $('.toggle-menu-feed-filters').addClass('hidden');
  $('.toggle').removeClass('toggled');
  $('.toggle').removeClass('toggled-logo');
  $('.toggle').removeClass('toggled-full-logo');
  $('.toggle').removeClass('toggled-icon-logo');
  $('.toggle').removeClass('toggled-no-logo');
}

function toggleDropdown() {
  
  //Gets the target toggleable menu from the link's data-attribute
  var target = $(this).attr('data-toggle');
  var logo_class = $(this).attr('data-logo_class');
  
  if ($(target).hasClass('hidden')) {
    // Opens the target toggle menu
    closeAllToggleMenus();
    $(target).removeClass('hidden');
    if($(this).hasClass('select-tribe')) {
      $(this).addClass('toggled-logo');
      if (logo_class != undefined) {
        $(this).addClass(logo_class);
      }
    } else {
      $(this).addClass('toggled');
    }
  } else {
    // Closes the target toggle menu
    $(target).addClass('hidden');
    $(this).removeClass('toggled');
    $(this).removeClass('toggled-logo');
    if (logo_class != undefined) {
      $(this).removeClass(logo_class);
    }
  }
  
}

$(function(){
  
  // Collapses all toggle menus on load
  // They're uncollapsed by default to provice support for when JS is turned off
  closeAllToggleMenus();
  $('.toggle').on('click', toggleDropdown);
    
});
