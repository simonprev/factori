defmodule Factori.GeneratedColumnTest do
  use Factori.EctoCase, async: true

  describe "generate column" do
    test "ALWAYS" do
      Factori.TestRepo.query!("""
        CREATE TABLE users (
        "generated" text NOT NULL GENERATED ALWAYS AS ('is generated') STORED
        )
      """)

      defmodule EctoGeneratedColumnUserFactory do
        use Factori, repo: Factori.TestRepo
      end

      EctoGeneratedColumnUserFactory.bootstrap()

      user = EctoGeneratedColumnUserFactory.insert("users")
      assert user.generated === "is generated"
    end
  end
end
