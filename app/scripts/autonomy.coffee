app = angular.module('autonomyApp', ['video'])

.controller("autonomyController", [
    '$scope',
    'videoService',
    ($scope, video) ->
        $scope.foundation = 'ooo la la'
        #video.postTest()
])


