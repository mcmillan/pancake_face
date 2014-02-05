filepicker.setKey('A5iPA0dMlTkG0ebazF5XCz')

$('a').on('click', (event) ->
  event.preventDefault()
  filepicker.pick(
    mimetype: 'image/*',
    services: ['FACEBOOK', 'INSTAGRAM', 'WEBCAM', 'COMPUTER']
  , (inkBlob) ->
    $('.upload').html('<p class="lead">Processing...</p>')
    $.ajax(
      url: '/'
      type: 'post'
      data:
        url: inkBlob.url
      success: (response) ->
        $('.upload').html("<img src='#{response.file}'>")
        console.log response
    )
  , (error) ->
    console.log error
  )
)