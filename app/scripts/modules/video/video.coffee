video = angular.module 'video', []

video.service 'videoService', ($http) ->
        payload = 'little birdie'
        postTest: ->
            request = $http.post('http://httpbin.org/post', { thePackage: @payload })
                .then (result) =>
                    console.log result
