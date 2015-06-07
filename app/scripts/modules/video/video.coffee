video = angular.module 'Video', []

video.controller('VideoController', [
  ->
    this.call = (id) ->
      console.log('call', id)
])

video.directive 'videoPlayer', [ '$http', ($http) ->
    {
        restrict: 'E',
        templateUrl: 'views/modules/video/videoPlayer.html'
        link: ($scope) ->

            $scope.onAir = false;

            server = {
                apiKey: 45214212
                sessionId: '1_MX40NTIxNDIxMn5-MTQzMzA5NzIxODA2MX5PN1ZLVGNlS1I2Yzc5STJWM3NuUGFiaTZ-fg'
                token: 'T1==cGFydG5lcl9pZD00NTIxNDIxMiZzaWc9ZmVkYTQ5ZDY3ODk0MGUxZWQ0OWI2NWNmM2ZlN2M5YmViZjJhYzA1ZTpyb2xlPXB1Ymxpc2hlciZzZXNzaW9uX2lkPTFfTVg0ME5USXhOREl4TW41LU1UUXpNekE1TnpJeE9EQTJNWDVQTjFaTFZHTmxTMUkyWXpjNVNUSldNM051VUdGaWFUWi1mZyZjcmVhdGVfdGltZT0xNDMzMDk3MjIyJm5vbmNlPTAuMzA5ODAxMzk5NzE1NjU0OCZleHBpcmVfdGltZT0xNDM1Njg4OTA5JmNvbm5lY3Rpb25fZGF0YT0='
                session: {}
                publisher: null

                createSession: ->
                    request = {
                        method: 'POST',
                        url: 'https://api.opentok.com/session/create',
                        headers: {
                            'X-TB-PARTNER-AUTH': this.apiKey + ':3beb94ec2b0ee7cdf64b42caaf6120baf543129b'
                        }
                        transformResponse: (data) ->
                            x2js = new X2JS();
                            json = x2js.xml_str2json(data);
                    }

                    $http(request);
            }

            videoController = {

                connectAs: (type) ->
                    this.type = type;

                getSubscriptionType: ->
                    if(this.type == 'host')
                        return 'guest'
                    else
                        return 'host'

                getPublisherType: ->
                    return this.type

                publishAudioAndVideo: (mode) ->

                publishAudioOnly: (server) ->
                    #only publish audio
                    pubOptions = {
                        publishVideo: false, #disable the video stream
                        height: 1,
                        width: 1
                    };

                    console.log('publisher options', pubOptions);

                    publisher = OT.initPublisher(this.type, pubOptions, (error) ->
                        if (error)
                            console.log('unable to publish');
                        else
                            console.log('Publisher initialized.');
                    );

                    server.session.publish(publisher);

                    return publisher;

                disconnect: (server) ->
                    server.session.unpublish(server.publisher);
                    server.session.unsubscribe(server.subscriber);
            }

            $scope.stopCall = () ->
                $scope.onAir = false;
                videoController.disconnect(server);

            $scope.startCall = ->
                $scope.onAir = true;

                videoController.connectAs('host');

                console.log('attempt to make contact');

                server.createSession().success((result)->
                    ######console.log('results', result.sessions.Session.session_id);
                    console.log('session created');
                    if (OT.checkSystemRequirements() == 1)
                        server.session = OT.initSession(server.apiKey, server.sessionId);

                        server.session.on("sessionConnected", (sessionConnectEvent) ->
                            console.log("sessionConnected executed");
                        );

                        server.session.on("streamCreated", (streamCreatedEvent) ->
                            console.log("streamCreated executed");
                            server.subscriber = server.session.subscribe(streamCreatedEvent.stream, videoController.getSubscriptionType());
                        );

                        server.session.on("sessionDestroyed", (stream) ->
                            console.log("sessionDestroyed executed");
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
                                            height: window.innerHeight,
                                            width: window.innerWidth
                                        };

                                        console.log('publisher options', pubOptions);

                                        server.publisher = OT.initPublisher(videoController.getPublisherType(), pubOptions, (error) ->
                                            if (error)
                                                # The client cannot publish.
                                                # You may want to notify the user.
                                                console.log('unable to publish');
                                            else
                                                console.log('Publisher initialized.');
                                        );

                                        server.session.publish(server.publisher);
                                    );
                                else
                                    console.log('publish not available');
                        );
                );

            $scope.joinCall = ->
                $scope.onAir = true;

                videoController.connectAs('guest');

                console.log('join the call');
                server.session = OT.initSession(server.apiKey, server.sessionId);

                server.session.on("sessionConnected", (sessionConnectEvent) ->
                    console.log("sessionConnected executed");
                );

                server.session.on("streamCreated", (streamCreatedEvent) ->
                    console.log("streamCreated executed");
                    server.subscriber = server.session.subscribe(streamCreatedEvent.stream, videoController.getSubscriptionType(), {
                        height: window.innerHeight,
                        width: window.innerWidth
                    });
                );

                server.session.on("sessionDestroyed", (stream) ->
                    console.log("sessionDestroyed executed");
                );

                server.session.connect(server.token, (error) ->
                    if (error)
                        console.log("Error connecting: ", error.code, error.message);
                    else
                        console.log("Connected to the session.");
                        if (server.session.capabilities.publish == 1)

                            server.publisher = videoController.publishAudioOnly(server);
                        else
                        console.log('publish not available');
                );
    }
]
