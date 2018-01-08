#
# Cookbook Name:: aet
# Library:: aet_artifacts
#
# AET Cookbook
#
# Copyright (C) 2016 Cognifide Limited
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

def setup_aet_artifact(artifact_type)
  ver = node['aet']['version']
  base_dir = node['aet']['karaf']['root_dir']
 
  create_aet_artifact_dir("#{base_dir}/aet_#{artifact_type}")

  
  url = "#{node['aet']['base_link']}/#{ver}/#{artifact_type}.zip"
  file = "#{node['aet']['karaf']['root_dir']}/aet_#{artifact_type}/#{artifact_type}-#{ver}.zip"
  download_artifact(url, file)

  extract_artifact(artifact_type, ver)

  # see `helpers.rb` file
  work_dir = "#{base_dir}/aet_#{artifact_type}"
  link_to_current_artifacts = "#{work_dir}/current"
  task_to_run_if_version_changed = "execute[extract-#{artifact_type}]"

  check_if_new(artifact_type,
               link_to_current_artifacts,
               "#{work_dir}/#{ver}",
               task_to_run_if_version_changed)
end

def create_aet_artifact_dir(path)
  directory path do
    owner node['aet']['karaf']['user']
    group node['aet']['karaf']['group']
    recursive true
    action :create
  end
end

def download_artifact(url, file)
  remote_file file do
    source url
    owner node['aet']['karaf']['user']
    group node['aet']['karaf']['group']
  end
end

# registers extraction task so that it could be called if needed
def extract_artifact(artifact_type, version)
  execute "extract-#{artifact_type}" do
    command "unzip -o #{artifact_type}-#{version}.zip -d #{version}"
    cwd "#{node['aet']['karaf']['root_dir']}/aet_#{artifact_type}"
    user node['aet']['karaf']['user']
    group node['aet']['karaf']['group']
    action :nothing
  end
end

# creates fileinstall config in Karaf deploy directory
def create_fileinstall_config(base_dir, artifact_type)
  target_file = "#{base_dir}/current/deploy/org.apache.felix.fileinstall-deploy-#{artifact_type}.cfg"

  template target_file do
    source 'content/karaf/current/etc/org.apache.felix.fileinstall-template.cfg.erb'
    owner node['aet']['karaf']['user']
    group node['aet']['karaf']['group']
    cookbook node['aet']['karaf']['src_cookbook']['bundles_cfg']
    mode '0644'
    variables(
      'base_dir' => base_dir,
      'artifact_type' => artifact_type
    )

    notifies :restart, 'service[karaf]', :delayed
  end
end
