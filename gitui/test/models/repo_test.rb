require 'test_helper'

class RepoTest < ActiveSupport::TestCase
  test 'should not create a new repo without a name' do
    repo = Repo.new
    assert_not repo.save, 'Created a new repo without a name'
  end
end
