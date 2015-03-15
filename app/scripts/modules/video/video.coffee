video = angular.module 'video', []

video.service 'videoService', ($http) ->
    payload = 'little birdie'
    apiKey: 45174472
    createSession: ->
        request = {
            method: 'POST',
            url: 'https://api.opentok.com/session/create',
            headers: {
                'X-TB-PARTNER-AUTH': this.apiKey + ':7c9d68bc8f1da4d2fd1a71211bed992d8e7a3685'
            }
            transformResponse: (data) ->
                x2js = new X2JS();
                json = x2js.xml_str2json( data );
        }

        $http(request);

    createToken: ->

video.controller 'videoController', ['$scope', 'videoService', ($scope, videoService) ->
    $scope.startCall = ->
        console.log('attempt to make contact');
        videoService.createSession().success((result)->
            console.log('results', result.sessions.Session.session_id);

            session = OT.initSession(videoService.apiKey, result.sessions.Session.session_id);

            publisher = OT.initPublisher('myPublisherDiv');

            token = 'T1==cGFydG5lcl9pZD00NTE3NDQ3MiZzaWc9YjE3ZWM5MmU1ZTIyMDU0YzMwYTM4YjE5YjAwYTRlYmJlOTI1NzgxMDpyb2xlPXB1Ymxpc2hlciZzZXNzaW9uX2lkPTJfTVg0ME5URTNORFEzTW41LU1UUXlOalExTkRFeE5qRXhNbjVJTkRCc01WZFJPRWRxTXpaaWNURklPVVZXVlhoclQzUi1mZyZjcmVhdGVfdGltZT0xNDI2NDU0MzE1Jm5vbmNlPTAuODU3NDk1NzQwMjg1MTA4NyZleHBpcmVfdGltZT0xNDI2NDU3NTQw'

            session.connect(token, (error) ->
                session.publish(publisher);
            );

            console.log(session);
        );
]

video.directive 'videoPlayer', ->
    {
        restrict: 'E',
        templateUrl: 'views/modules/video/video.html'
    }
