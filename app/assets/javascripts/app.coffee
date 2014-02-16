#= require detector
#= require facebookPicker
#= require webcamPicker
#= require instagramPicker
#= require generator

@Pancake.FacebookPicker.init()
@Pancake.InstagramPicker.init()
@Pancake.Generator.init()

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

$('section.step-2 .js-step-back').on('click', (event) ->
  event.preventDefault()
  $('section.step-1 .state')
    .hide()
    .filter('.state-intro')
    .show()

  $('.steps-list li[data-step=2]').removeClass('selected')

  $('section.step-1 .state.state-face-selector .faces').empty()

  $('section.step-2').fadeOut(300).promise().done(->
    $('section.step-1').fadeIn(300)
  )
)