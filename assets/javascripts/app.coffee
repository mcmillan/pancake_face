#= require detector
#= require facebookPicker
#= require webcamPicker
#= require instagramPicker

@Pancake.FacebookPicker.init()
@Pancake.InstagramPicker.init()

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

$('.state.state-face-selector .faces').on('click', '.face', (event) ->
  event.preventDefault()
  id = $(this).data('id')
  $('.state.state-face-selector').fadeOut(300).promise().done(->
    $('.state.state-loading').fadeIn(300).promise().done(->
      $.ajax(
        url: '/generate'
        type: 'post'
        data:
          id: id
        success: (response) ->
          $('section.step-1').fadeOut(300).promise().done(->
            $('section.step-2').append("<img src='#{response.file}'>").fadeIn(300)
          )
        error: ->
          alert 'Something went wrong. Try again?'
      )
    )
  )
)