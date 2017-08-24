source "https://github.com/CocoaPods/Specs"
use_frameworks!

def shared_pods
    pod 'JSONWebToken', '~> 2'
    pod 'Alamofire', '~> 4'
    pod 'Result', '~> 3'
end

target 'MATRIX Auth SDK macOS' do
    platform :osx, '10.10'
    shared_pods

    target 'MATRIX Auth SDK macOS Tests' do
        inherit! :search_paths
    end
end

target 'MATRIX Auth SDK iOS' do
    platform :ios, '8.0'
    shared_pods

    target 'MATRIX Auth SDK iOS Tests' do
        inherit! :search_paths
    end
end

target 'MATRIX Auth SDK watchOS' do
    platform :watchos, '2.0'
    shared_pods
end

target 'MATRIX Auth SDK tvOS' do
    platform :tvos, '9.0'
    shared_pods

    target 'MATRIX Auth SDK tvOS Tests' do
        inherit! :search_paths
    end
end
