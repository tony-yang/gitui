require 'test_helper'

class ReposControllerTest < ActionDispatch::IntegrationTest
  setup do
    @new_repo_name = 'testrepo1'
    @repo_inside_container_url = "/db/gitui/#{@new_repo_name}.git"
  end

  teardown do
    if Dir.exist? @repo_inside_container_url
      FileUtils.rm_r @repo_inside_container_url
    end
  end

  test 'should get index' do
    get repos_url
    assert_response :success
  end

  test 'should create a new repo when the new repo name is unique' do
    assert_difference('Repo.count') do
      post repos_url, params: { repo: {
        name: @new_repo_name,
        readme: '1'
      }}
    end
    assert(Dir.exist?(@repo_inside_container_url), 'Failed to create a new repo')
    assert_redirected_to repo_path((@new_repo_name))
  end

  test 'should not create a new repo when creating a new repo with duplicated repo name' do
    post repos_url, params: { repo: {
      name: @new_repo_name,
      readme: '1'
    }}

    assert_no_difference('Repo.count') do
      post repos_url, params: { repo: {
        name: @new_repo_name,
        readme: '1'
      }}
    end
  end

  test 'should give an error meesage when creating a new repo with duplicated repo name' do
    post repos_url, params: { repo: {
      name: @new_repo_name,
      readme: '1'
    }}

    post repos_url, params: { repo: {
      name: @new_repo_name,
      readme: '1'
    }}

    assert_equal 'The repository name already exists!', flash[:error]
  end
end
