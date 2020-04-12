platform :ios, '10.0'

source 'https://github.com/CocoaPods/Specs.git'

#first cp ./demo/dev.podspec ./dev.podspec
def shared_pods
  pod 'gobelieve', :path => './dev.podspec'
end

target 'im_demo' do
  use_frameworks!  
  shared_pods
end

target 'group_demo' do
  use_frameworks!    
  shared_pods
end

target 'room_demo' do
  use_frameworks!    
  shared_pods
end

target 'customer_demo' do
  use_frameworks!    
  shared_pods
end

