class AddVotedContributionsToUser < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :voted_contribution_ids, :string
    add_column :users, :voted_comment_ids, :string
  end
end
