video = angular.module 'video', []

video.service 'videoService',
    class Video
        constructor: (@$http) ->
            @payload = 'little birdie'
            @postTest()

        postTest: ->
            request = @$http.post 'http://httpbin.org/post', { thePackage: @payload }
            request.then (result) =>
                console.log result

injector = angular.injector ['video', 'ng']

injector.invoke (videoService) ->
    console.log "'defined'"
