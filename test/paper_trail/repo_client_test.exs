defmodule PaperTrail.OptTest do
  use ExUnit.Case

  describe "&repo/1: " do
    test "with dynamic repo" do
      {:ok, _} = PaperTrail.Repo.start_link(name: :dynamic_repo)

      repo = PaperTrail.Opt.repo(repo: {PaperTrail.Repo, :dynamic_repo})

      assert {:ok, _} = repo.query("SELECT 1")
    end
  end
end
