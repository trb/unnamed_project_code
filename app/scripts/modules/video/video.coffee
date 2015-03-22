video = angular.module 'Video', []

video.directive 'videoPlayer', [ '$http', ($http) ->
    {
        restrict: 'E',
        templateUrl: 'views/modules/video/videoPlayer.html'
        link: ($scope) ->

            server = {
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
                            json = x2js.xml_str2json(data);
                    }

                    $http(request);
            }

            $scope.startCall = ->
                console.log('attempt to make contact');
                server.createSession().success((result)->
                    console.log('results', result.sessions.Session.session_id);

                    sessionId = '2_MX40NTE3NDQ3Mn5-MTQyNTgzODcxNzEyMX5CWjNmUXJXQ2g5YUZ5MTZ0eFBvNXJtcDJ-fg';

                    session = OT.initSession(server.apiKey, sessionId);

                    token = 'T1==cGFydG5lcl9pZD00NTE3NDQ3MiZzaWc9M2EyN2I4Mzg0YjJhNTRkNGNmZjIzMDU3OTFlMDg2MWNmYzA1NTkwZTpyb2xlPXB1Ymxpc2hlciZzZXNzaW9uX2lkPTJfTVg0ME5URTNORFEzTW41LU1UUXlOVGd6T0RjeE56RXlNWDVDV2pObVVYSlhRMmc1WVVaNU1UWjBlRkJ2TlhKdGNESi1mZyZjcmVhdGVfdGltZT0xNDI3MDUxMzQ1Jm5vbmNlPTAuMTUzNjczNzQxMjM2NTk2OTQ='

                    session.on({
                        streamCreated: (event) ->
                            session.subscribe(event.stream, 'subscribersDiv', {insertMode: 'append'});
                    });

                    session.connect(token, (error) ->
                        if (error)
                            console.log(error);
                        else
                            session.publish('myPublisherDiv', {width: 1920, height: 1080});
                    );

                    console.log(session);
                );
    }
]
