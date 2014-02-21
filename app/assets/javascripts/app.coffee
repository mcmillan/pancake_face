#= require detector
#= require facebookPicker
#= require webcamPicker
#= require instagramPicker
#= require generator
#= require gallerySubmission

@Pancake.FacebookPicker.init()
@Pancake.InstagramPicker.init()
@Pancake.Generator.init()
@Pancake.GallerySubmission.init()

$('.js-pick-webcam').on('click', @Pancake.WebcamPicker.show)
$('.js-pick-facebook').on('click', @Pancake.FacebookPicker.show)
$('.js-pick-instagram').on('click', @Pancake.InstagramPicker.show)

$('.js-pick-computer input').fileupload(
  dataType: 'json'
  url: '/detect'
  formData:
    type: 'computer'
  add: (event, data) ->
    $('.state.state-intro').fadeOut(300).promise().done(->
      $('.state.state-loading').fadeIn(300).promise().done(-> data.submit())
    )
  done: (event, data) ->
    Pancake.Detector.success(data.response().result)
)

$('section.customise .js-step-back').on('click', (event) ->
  event.preventDefault()

  # This is an extremely unpleasant way of handling state, refactor
  if $('.steps-list li[data-step=3]').hasClass('selected')
    $('.customise .tweaker-wrapper .tweaker, section.customise .js-step-next').fadeIn(500)
    $('.customise .pan-switcher').slideDown(500)
    $('.gallery-submission, .customise .sharing').slideUp(500)
    $('.steps-list li[data-step=3]').removeClass('selected')
  else
    $('section.upload .state')
      .hide()
      .filter('.state-intro')
      .show()

    $('.steps-list li[data-step=2]').removeClass('selected')

    $('section.upload .state.state-face-selector .faces').empty()

    $('section.customise').fadeOut(300).promise().done(->
      $('section.upload').fadeIn(300)
    )
)

$('section.customise .js-step-next').on('click', (event) ->
  event.preventDefault()

  $('.customise .tweaker-wrapper .tweaker, .customise .img-controls a').fadeOut(300)
  $('.customise .pan-switcher').slideUp(300)
  $('.customise .tweaker-wrapper > img').fadeTo(300, 0)
  $('.customise .tweaker-wrapper .tweaker, .customise .img-controls a, .customise .tweaker-wrapper > img, .customise .pan-switcher').promise().done(->
    $.ajax(
      url: '/gallery'
      type: 'post'
      complete: (jqXHR, status) ->
        $('.gallery-submission, .customise .sharing').slideDown(300)
        $('.customise .tweaker-wrapper > img').fadeTo(300, 1)
        $('.steps-list li[data-step=3]').addClass('selected')
        Pancake.Generator.focusImage()
        return unless status == 'success'
        addthis.toolbox('.addthis_toolbox', {}, url: jqXHR.responseJSON.shareURL)
        $('.customise .sharing .plugins .fb-send').attr('data-href', jqXHR.responseJSON.shareURL)
        FB.XFBML.parse()          
    )
  )
)