export default class MainView {
  mount() {
    // This will be executed when the document loads...
    console.log('MainView mounted')
    $(document).ready(function() {
      // Assign global variable to support functions
      var global = (1,eval)('this')
      init_custom_actions()
    });
  }

  unmount() {
    // This will be executed when the document unloads...
    console.log('MainView unmounted')
  }
}


// ------------- GLOBAL METHODS  -----------------------------------------------------------------
  global.validateMyanmarMobileNumber = (str) => {
      return /^([09]{1})([0-9]{10})$/.test(str)
  }
  global.validateEmail = (str) => {
    var re = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
    return re.test(str);
  }
  global.validatePrice = (str) => {
      return /^([1-9]{1})([0-9]{1,9})?$/.test(str)
  }
  global.reset_announce_form_field = () => {
    // Triggered if a wrong phone number is processed to the form
    console.log("wrong phone number : form reseted")
    $('.collapsible_form').collapse('hide')
    $('#announce_phone_number').val('').focus().removeClass("field-success")
    $('#announce_email').val('')
    $('#announce_price').val('')
    $('#announce_user_id').val('')
  }
  global.validate_phone_number_pop_field = (user_id, nickname, email, password, viber) => {
    // Good phone number is processed to the form and user is known
    console.log("Good phone number : form processed with pop")
    $('#announce_phone_number').addClass("field-success")
    $('.collapsible_form').collapse('show')
    $('#announce_user_id').val(user_id)
    $('#announce_nickname').val(nickname).focus()
    $('#announce_email').val(email)
    if (password == "") {$('#field-password').hide()}
    else {$('#field-password').show()}
    if (viber == "true") {
      $('#field-viber').show()
      $('#btn-viber').hide()
    } else {
      $('#field-viber').hide()
      $('#btn-viber').show()
    }
  }

  global.scrollToAnchor = (aid) => {
    // var aTag = $("a[name='"+ aid +"']");
    var aTag = $("[name='"+ aid +"']");
    $('html,body').animate({scrollTop: aTag.offset().top},'slow');
  }

  // $.wait = (ms) => {
  //   var defer = $.Deferred();
  //   setTimeout(function() { defer.resolve(); }, ms);
  //   return defer;
  // };

// ------------- Initialization  -----------------------------------------------------------------

  let init_custom_actions = () => {
    // Set up the lightbox - http://ashleydw.github.io/lightbox/#no-wrapping
    $(document).on('click', '[data-toggle="lightbox"]', function(event) {
        event.preventDefault();
        $(this).ekkoLightbox();
    });

    // Correct behaviour on the multiselect items
    $('.submenu-item-hover').on('click', function(event) {
      $(this).mouseenter()
      event.stopPropagation()
    })

    // Click on the see number
    $('.btn-show-number').on('click', function() {
      var announce_id = $(this).attr('data-announce-id')
      var phone_number = $(this).attr('data-phone-number')
      $(this).addClass('d-none')
      $(`#number_${announce_id}`).removeClass('d-none')

      var $temp = $("<input>")
      $("body").append($temp)
      $temp.val(phone_number).select()
      document.execCommand("copy")
      $temp.remove()
    })

    // Click on a small announce
    $('.btn-small-announce').on('click', function() {
      $(".small-announce").removeClass('d-none')
      $(".big-announce").addClass('d-none')
      var announce_id = $(this).attr('data-announce-id')
      $(`#small_announce_${announce_id}`).addClass('d-none')
      $(`#big_announce_${announce_id}`).removeClass('d-none')
      scrollToAnchor(`big_announce_${announce_id}`)
    })

    // Click on a big announce
    $('.btn-big-announce').on('click', function() {
      var announce_id = $(this).attr('data-announce-id')
      $(`#small_announce_${announce_id}`).removeClass('d-none')
      $(`#big_announce_${announce_id}`).addClass('d-none')
      scrollToAnchor(`small_announce_${announce_id}`)
    })

    // Boostrap 4 caroussel 1st elements active selection
    $('.carousel-inner').each(function(){
      $(this).children(":first").addClass('active');
    })
    $('.carousel-indicators').each(function(){
      $(this).children(":first").addClass('active');
    })
    $('.carousel').carousel({interval: false})
    $(".carousel-inner").swipe({
      swipeLeft:function(event, direction, distance, duration, fingerCount) {
          $(this).parent().carousel('next');
      },
      swipeRight: function() {
          $(this).parent().carousel('prev');
      },
      threshold:75
    })

    // Currency selector
    $('.ddown_change_currency').on('click', function() {
      console.log(this.innerHTML)
      $('#choosen_currency_text')[0].innerHTML = this.innerHTML
      $('#announce_currency').val(this.innerHTML)
    })

    // Get the title and check if it looks like Zawgyi
    $('#announce_email').on('change', function() {
      var email = $(this).val()
      if (validateEmail(email) == false) {
        console.log("wrong email")
        $(this).val('').focus()
      }
    })

    $('#announce_title').on('change', function() {
      var title = $(this).val()
      if (knayi.fontDetect(title) == "zawgyi") {
        console.log("zawgyi detected")
        $('#announce_zawgyi').val('true')
      } else {
        console.log("unicode detected")
        $('#announce_zawgyi').val('false')
      }
    })

    $('#announce_price').on('change', function() {
      var price = $(this).val()
      var rounded_price = Math.round(price)
      if(isNaN(rounded_price)) {
        rounded_price = "";
      }
      $(this).val(rounded_price).focus()
    })
  }


// let init_navigation = () => {
//   $('select').material_select()
//   $('.empty_fields').click(function(){
//     $('#search_form').clear().submit()
//   })
// }
//
// let init_slidebars = () => {
//   $('#btn_slidebar_left').sideNav({
//       menuWidth: 300, // Default is 300
//       edge: 'left', // Choose the horizontal origin
//       closeOnClick: true, // Closes side-nav on <a> clicks, useful for Angular/Meteor
//       draggable: true // Choose whether you can drag to open on touch screens
//     }
//   )
//   $('#btn_slidebar_right').sideNav({
//       menuWidth: 300, // Default is 300
//       edge: 'right', // Choose the horizontal origin
//       closeOnClick: true, // Closes side-nav on <a> clicks, useful for Angular/Meteor
//       draggable: true // Choose whether you can drag to open on touch screens
//     }
//   )
//   console.log("Sidebars mounted")
// }
// let destroy_slidebars= () => {
//   $('#btn_slidebar_left').sideNav('destroy')
//   $('#btn_slidebar_right').sideNav('destroy')
//   console.log("Sidebars destroyed")
// }
//
// let init_toast= () => {
//   $(document).on('click', '#toast-container .toast', function() {
//     $(this).fadeOut(function(){
//       // hide the toast bu dont remove it since Materialize will do it later
//       // See in fhash function
//     })
//   })
// }
//
// let init_dropdown = () => {
//   $(".dropdown-button").dropdown(
//     { hover: true }
//   );
// }
//
// let init_flash = () => {
//   $('.flash_msg').hide()
//   $('.flash_msg').on('touchstart click', function() {
//     $(this).fadeOut( "slow", function() {
//       // console.log("clicked")
//     });
//   });
//   setTimeout(function(){
//     $('.flash_msg').fadeIn(1000)
//     console.log("Flash fired In");
//   }, 1000);
//   setTimeout(function(){
//     $('.flash_msg').fadeOut(800)
//     //console.log("Flash fired Out");
//   }, 5000)
//   // console.log("Flash fired");
// }
//
// let init_mobile_chrome_vh_fix = () => {
//   var vhFix = new VHChromeFix([
//     {
//       selector: '.player',
//       vh: 100
//     },
//     {
//       selector: '.Foxes',
//       vh: 50
//     }
//   ]);
// }


// global.choose_random = (list) => {
//   return list[Math.floor(Math.random()*list.length)]
// }
//
// // Clear search fields
// jQuery.fn.clear = function(){
//     var $form = $(this)
//     $form.find('input:text, input:password, input:file, textarea').val('')
//     $form.find('select option:selected').removeAttr('selected')
//     $form.find('input:checkbox, input:radio').removeAttr('checked')
//     return this
// };
//
// global.update_progress_bar = (bar_id, cards_list) => {
//   var total = cards_list.length
//   var level1_share = cards_list.filter(card => card.status == 1).length / total * 100
//   var level2_share = cards_list.filter(card => card.status == 2).length / total * 100
//   var level3_share = cards_list.filter(card => card.status == 3).length / total * 100
//   var level0_share = 100 - level1_share - level2_share - level3_share
//   // console.log(total)
//   // console.log([level0_share, level1_share, level2_share, level3_share])
//   // console.log("level0_share : " + level0_share + ", level1_share : " + level1_share + ", level2_share : " + level2_share)
//   // console.log(bar_id)
//   $(`#${bar_id}`).find('.level0').css('width', level0_share + '%')
//   $(`#${bar_id}`).find('.level1').css('width', level1_share + '%')
//   $(`#${bar_id}`).find('.level2').css('width', level2_share + '%')
//   $(`#${bar_id}`).find('.level3').css('width', level3_share + '%')
//   // The bar is ordered : next div is the previous level...
//   // `#${bar_id} > .progress-item`
//   $(`#${bar_id} > .progress-item`).each(function(){
//     if ($(this).next(".progress-item").width() > 0) {
//       $(this).removeClass("right_corner")
//     } else {
//       $(this).addClass("right_corner")
//     }
//     if ($(this).prev(".progress-item").width() > 0) {
//       $(this).removeClass("left_corner")
//     } else {
//       $(this).addClass("left_corner")
//     }
//   });
// }
//

// $('.btn_get_number').on('click', function() {
//   console.log(this.id)
//   this.addClass("d-none")
// })
// $('.link_big_announce').on('click', function() {
//   // this.
// })

// $('#announce_phone_number').on('change', function() {
//   var number = $(this).val()
//   if (validateMyanmarMobileNumber(number) == false) {
//     console.log("wrong phone number")
//     $(this).val('').focus().removeClass("field-success")
//     $('.collapsible_form').collapse('hide')
//   } else {
//     $(this).addClass("field-success")
//     $('.collapsible_form').collapse('show')
//   }
// })
//
// $('#btn_check_number').on('click', function() {
//   var number = $('#announce_phone_number').val()
//   if (validateMyanmarMobileNumber(number) == false) {
//     console.log("wrong phone number")
//     $('#announce_phone_number').val('').focus().removeClass("field-success")
//     $('.collapsible_form').collapse('hide')
//   } else {
//     $('#announce_phone_number').addClass("field-success")
//     $('.collapsible_form').collapse('show')
//   }
// })
