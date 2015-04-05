video = angular.module 'Video', []

video.directive 'videoPlayer', [ '$http', ($http) ->
    {
        restrict: 'E',
        templateUrl: 'views/modules/video/videoPlayer.html'
        link: ($scope) ->

            server = {
                apiKey: 45174472
                sessionId: '2_MX40NTE3NDQ3Mn5-MTQyNTgzODcxNzEyMX5CWjNmUXJXQ2g5YUZ5MTZ0eFBvNXJtcDJ-fg'
                token: 'T1==cGFydG5lcl9pZD00NTE3NDQ3MiZzaWc9NDNlZWMxY2YzNTc0YmY3ZjMyODlhMTMyOWZjNzlmZWRlOGJmZTA2NTpyb2xlPXB1Ymxpc2hlciZzZXNzaW9uX2lkPTJfTVg0ME5URTNORFEzTW41LU1UUXlOVGd6T0RjeE56RXlNWDVDV2pObVVYSlhRMmc1WVVaNU1UWjBlRkJ2TlhKdGNESi1mZyZjcmVhdGVfdGltZT0xNDI4MjU1ODY1Jm5vbmNlPTAuOTYzOTA4MjA5MTU5NzEwMSZleHBpcmVfdGltZT0xNDI4MzQyMjY1'
                session: {}

                createSession: ->
                    reguest = {
                        method: 'POST',
                        url: 'https://api.opentok.com/session/create',
                        headers: {
                            'X-TB-PARTNER-AUTH': this.apiKey + ':7c9d68bc8f1da4d2fd1a71211bed992d8e7a3685'
                        }
                        transformResponse: (data) ->
                            x2js = new X2JS();
                            json = x2js.xml_str2json(data);
                    }

                    $http(reguest);
            }

            $scope.startCall = ->
                console.log('attempt to make contact');

                server.createSession().success((result)->
                    console.log('results', result.sessions.Session.session_id);
                    if (OT.checkSystemRequirements() == 1)
                        server.session = OT.initSession(server.apiKey, server.sessionId);

                        server.session.on("sessionConnected", (sessionConnectEvent) ->
                            console.log("sessionConnected executed");

                        );

                        server.session.on("streamCreated", (streamCreatedEvent) ->
                            console.log("streamCreated executed");
                            server.session.subscribe(streamCreatedEvent.stream, 'guest');
                        );

                        server.session.connect(server.token, (error) ->
                            if (error)
                                console.log("Error connecting: ", error.code, error.message);
                            else
                                console.log("Connected to the session.");
                                if (server.session.capabilities.publish == 1)
                                    console.log('can publish');
                                    OT.getDevices((error, devices) ->

                                        audioDevices = [];
                                        videoDevices = [];

                                        console.log(arguments);
                                        $scope.devices = devices;
                                        $scope.$apply();

                                        audioInputDevices = devices.filter((element) ->
                                            return element.kind == "audioInput";
                                        );
                                        videoInputDevices = devices.filter((element) ->
                                            return element.kind == "videoInput";
                                        );
                                        for device in audioInputDevices
                                            audioDevices.push(device.deviceId);
                                            console.log("audio input device: ", device.deviceId);

                                        for device in videoInputDevices
                                            videoDevices.push(device.deviceId);
                                            console.log("video input device: ", device.deviceId);

                                        pubOptions = {
                                            #audioSource: audioDevices[1],
                                            videoSource: videoDevices[1], #second camera on phone, will need to be able to select
                                            mirror: false,
                                            width: 598,
                                            height: 360
                                        };

                                        console.log('publisher options', pubOptions);

                                        publisher = OT.initPublisher('host', pubOptions, (error) ->
                                            if (error)
                                                # The client cannot publish.
                                                # You may want to notify the user.
                                                console.log('unable to publish');
                                            else
                                                console.log('Publisher initialized.');
                                        );

                                        server.session.publish(publisher);

                                        $scope.stopCall = () ->
                                            server.session.unpublish(publisher);
                                            console.log('this should stop the call');
                                    );
                                else
                                    console.log('publish not available');
                        );
                );

            $scope.joinCall = ->
                console.log('join the call');
                server.session = OT.initSession(server.apiKey, server.sessionId);

                server.session.on("sessionConnected", (sessionConnectEvent) ->
                    console.log("sessionConnected executed");
                );

                server.session.on("streamCreated", (streamCreatedEvent) ->
                    console.log("streamCreated executed");
                    server.session.subscribe(streamCreatedEvent.stream, 'host');
                );

                server.session.connect(server.token, (error) ->
                    if (error)
                        console.log("Error connecting: ", error.code, error.message);
                    else
                        console.log("Connected to the session.");
                        if (server.session.capabilities.publish == 1)

                            pubOptions = {
                                videoSource: null
                            };

                            console.log('publisher options', pubOptions);

                            publisher = OT.initPublisher('guest', pubOptions, (error) ->
                                if (error)
                                    console.log('unable to publish');
                                else
                                    console.log('Publisher initialized.');
                            );

                            server.session.publish(publisher);

                            $scope.stopCall = () ->
                                server.session.unpublish(publisher);
                                console.log('this should stop the call');
                        else
                        console.log('publish not available');
                );
    }
]
