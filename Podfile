platform :ios, '8.0'

source 'https://github.com/CocoaPods/Specs.git'

#first cp ./demo/dev.podspec ./dev.podspec
def shared_pods
  pod 'gobelieve', :path => './dev.podspec'
end

target 'im_demo' do
  shared_pods
end

target 'group_demo' do
  shared_pods
end

target 'room_demo' do
  shared_pods
end

target 'customer_demo' do
  shared_pods
end


#https://github.com/CocoaPods/CocoaPods/issues/8122
post_install do |installer|
  project_path = 'im_demo.xcodeproj'
  project = Xcodeproj::Project.open(project_path)
  project.targets.each do |target|
    build_phase = target.build_phases.find { |bp| bp.display_name == '[CP] Copy Pods Resources' }
    
    if build_phase.present?
      target.build_phases.delete(build_phase)
    end
  end
  
  project.save(project_path)
end
