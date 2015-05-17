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
                sessionId: '1_MX40NTIxNDIxMn5-MTQyOTQ3MTM0NTcwMX5tZWQrK1lNOWozU2ZyMk9DcnRIU1hQQVJ-fg'
                token: 'T1==cGFydG5lcl9pZD00NTIxNDIxMiZzaWc9NmNlNmNmYjk5Y2FlNzEwNTA3M2Y1ZDYxODc5NjY4MjRhNjBlYWNiMDpyb2xlPXB1Ymxpc2hlciZzZXNzaW9uX2lkPTFfTVg0ME5USXhOREl4TW41LU1UUXlPVFEzTVRNME5UY3dNWDV0WldRcksxbE5PV296VTJaeU1rOURjblJJVTFoUVFWSi1mZyZjcmVhdGVfdGltZT0xNDMxODg2MDk5Jm5vbmNlPTAuNzc4OTY0NTI3MzI5NzQ='
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

                publishAudioOnly: () ->
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
            }

            $scope.stopCall = () ->
                $scope.onAir = false;
                server.session.unpublish(server.publisher);
                server.session.unsubscribe(server.currentStream);
                server.session.disconnect();
                console.log('this should stop the call');

            $scope.startCall = ->
                $scope.onAir = true;

                videoController.connectAs('host');

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
                            server.session.subscribe(streamCreatedEvent.stream, videoController.getSubscriptionType());
                            server.currentStream = streamCreatedEvent.stream;
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
                    server.session.subscribe(streamCreatedEvent.stream, videoController.getSubscriptionType(), {
                        height: window.innerHeight,
                        width: window.innerWidth
                    });
                    server.currentStream = streamCreatedEvent.stream;
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

                            publisher = videoController.publishAudioOnly();
                        else
                        console.log('publish not available');
                );
    }
]
