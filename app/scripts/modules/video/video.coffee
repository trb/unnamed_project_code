video = angular.module 'video', []

video.service 'videoService', ($http) ->
    payload = 'little birdie'
    createSession: ->
        request = {
            method: 'POST',
            url: 'https://api.opentok.com/session/create',
            headers: {
                'X-TB-PARTNER-AUTH': '45174472:7c9d68bc8f1da4d2fd1a71211bed992d8e7a3685'
            }
            transformResponse: (data) ->
                x2js = new X2JS();
                json = x2js.xml_str2json( data );
        }

        $http(request);

video.controller 'videoController', ['$scope', 'videoService', ($scope, videoService) ->
    $scope.startCall = ->

        console.log('attempt to make contact');
        videoService.createSession().success((result)->
            console.log('results', result);
        );

        apiKey = "45174472";
        sessionId = "2_MX40NTE3NDQ3Mn5-MTQyNTgzODcxNzEyMX5CWjNmUXJXQ2g5YUZ5MTZ0eFBvNXJtcDJ-fg";
        token = "T1==cGFydG5lcl9pZD00NTE3NDQ3MiZzaWc9MjU4MzU2MmRiYjgwZDM1MGFhNDA0YjhlY2Y0YTBkYjRkNjQ2ODBlYTpyb2xlPXB1Ymxpc2hlciZzZXNzaW9uX2lkPTJfTVg0ME5URTNORFEzTW41LU1UUXlOVGd6T0RjeE56RXlNWDVDV2pObVVYSlhRMmc1WVVaNU1UWjBlRkJ2TlhKdGNESi1mZyZjcmVhdGVfdGltZT0xNDI1ODM4NzI0Jm5vbmNlPTAuMjQyNzMzNzMwMjQzNDAxNzI=";

        session = OT.initSession(apiKey, sessionId);
        session.on("streamCreated", (event) ->
            session.subscribe(event.stream);
        );

        session.connect(token, (error) ->
            publisher = OT.initPublisher();
            session.publish(publisher);
        );
]

video.directive 'videoPlayer', ->
    {
        restrict: 'E',
        templateUrl: 'views/modules/video/video.html'
    }
