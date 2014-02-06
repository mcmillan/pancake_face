filepicker.setKey('A5iPA0dMlTkG0ebazF5XCz')

filepicker.pick(
  mimetype: 'image/*',
  services: ['FACEBOOK', 'INSTAGRAM', 'WEBCAM', 'COMPUTER']
  container: 'picker'
, (inkBlob) ->
  $('#picker').fadeOut(300)
  $('#upload').html('<p class="lead">Processing...</p>').delay(300).fadeIn(300)
  $.ajax(
    url: '/'
    type: 'post'
    data:
      url: inkBlob.url
    success: (response) ->
      $('#upload').html("<img src='#{response.file}'>")
      console.log response
  )
, (error) ->
  console.log error
)