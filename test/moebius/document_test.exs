defmodule Moebius.DocTest do
  use ExUnit.Case
  import Moebius.DocumentQuery

  setup do
    "delete from user_docs;" |> TestDb.run()
    "drop table if exists monkies;" |> TestDb.run()
    doc = [email: "steve@test.com", first: "Steve", money_spent: 500, pets: ["poopy", "skippy"]]

    monkey = %{sku: "stuff", name: "Chicken Wings", description: "duck dog lamb"}

    db(:monkies)
    |> searchable([:name, :description])
    |> TestDb.save(monkey)

    {:ok, res} =
      db(:user_docs)
      |> TestDb.save(doc)

    {:ok, res: res}
  end

  test "A document table will created by calling create_document_table" do
    res = TestDb.create_document_table(:poop)
    assert res == {:ok, "Table created"}
  end

  test "a document can be saved if one of the values has a single quote" do
    "drop table if exists artists;" |> TestDb.run()

    thing = %{
      collections: ["equipment"],
      cost: 67743,
      description:
        "Why walk **when you can fly**! Weak Martian gravity means you too can fly wherever you want, whenever you want with some rockets on your back. Light, portable and really loud - you'll be the talk of the Martian skies! ",
      domain: "localhost",
      image: "johnny-liftoff.jpg",
      inventory: 43,
      name: "Johnny Liftoff Rocket Suit",
      price: 8_933_300,
      published_at: "2016-02-12T01:21:29.147Z",
      sku: "johnny-liftoff",
      status: "published",
      summary: "Keep your feet off the ground with our space-age rocket suit",
      vendor: %{name: "Martian Armaments, Ltd", slug: "martian-armaments"}
    }

    {:ok, res} = db(:artists) |> TestDb.save(thing)
    assert res.sku == "johnny-liftoff"
  end

  test "save creates table if it doesn't exist" do
    "drop table if exists artists;" |> TestDb.run()
    {:ok, res} = db(:artists) |> TestDb.save(%{name: "Spiff"})
    assert res.name == "Spiff"
  end

  test "nil is returned when id is not found in docs" do
    {:ok, res} = db(:monkies) |> TestDb.find(155_555)
    assert res == nil
  end

  test "the document is returned with find" do
    {:ok, res} = db(:monkies) |> TestDb.find(1)
    assert res.name == "Chicken Wings"
  end

  test "the document is returned with created and updated" do
    {:ok, res} = db(:monkies) |> TestDb.find(1)
    assert res.created_at
  end

  test "updated_at is overridden" do
    {:ok, res} = db(:monkies) |> TestDb.save(%{name: "bip", updated_at: "poop"})
    assert res.updated_at == res.created_at
  end

  test "saving a struct" do
    thing = %TestCandy{}
    {:ok, res} = db(:monkies) |> TestDb.save(thing)
    assert res.id
  end

  test "returns a struct if a struct was passed in" do
    thing = %TestCandy{}
    assert thing.__struct__ == TestCandy
    {:ok, res} = db(:monkies) |> TestDb.save(thing)
    assert res.__struct__ == TestCandy
  end

  test "can pull out a single record by id with find" do
    {:ok, res} = db(:monkies) |> TestDb.find(1)
    assert res.id == 1
  end

  test "first creates table if it doesn't exist" do
    "drop table if exists artists;" |> TestDb.run()
    {:ok, res} = db(:artists) |> TestDb.first()

    case res do
      {:error, _err} -> flunk("Nope")
      res -> res
    end
  end

  test "save creates table if it doesn't exist even when an id is included" do
    "drop table if exists artists;" |> TestDb.run()
    assert {:ok, %{name: "jeff", id: 1}} = db(:artists) |> TestDb.save(%{name: "jeff", id: 100})
  end

  test "a simple insert as a list returns the record", %{res: res} do
    assert res.email == "steve@test.com"
  end

  test "a simple insert as a list returns the id", %{res: res} do
    assert res.id > 0
  end

  test "a simple insert as a map" do
    doc = %{email: "steve@test.com", first: "Steve"}

    {:ok, res} =
      db(:user_docs)
      |> TestDb.save(doc)

    assert res.id > 0
  end

  test "a simple document query with the DocumentQuery lib" do
    assert {:ok, [%{email: "steve@test.com", id: _id}]} =
             db(:user_docs)
             |> TestDb.run()
  end

  test "a simple single document query with the DocumentQuery lib" do
    assert {:ok, %{email: "steve@test.com", id: _id}} =
             db(:user_docs)
             |> TestDb.first()
  end

  test "updating a document", %{res: res} do
    change = %{email: "blurgh@test.com", id: res.id}

    assert {:ok, %{email: "blurgh@test.com", id: _id}} =
             db(:user_docs)
             |> TestDb.save(change)
  end

  test "the save shortcut inserts a document without an id" do
    new_doc = %{email: "new_person@test.com"}

    assert {:ok, %{email: "new_person@test.com", id: _id}} =
             db(:user_docs)
             |> TestDb.save(new_doc)
  end

  test "the save shortcut works updating a document", %{res: _res} do
    change = %{email: "blurgh@test.com"}

    assert {:ok, %{email: "blurgh@test.com", id: _id}} =
             db(:user_docs)
             |> TestDb.save(change)
  end

  test "delete works with just an id", %{res: res} do
    {:ok, res} =
      db(:user_docs)
      |> delete(res.id)
      |> TestDb.first()

    assert res.id
  end

  test "delete works with criteria", %{res: res} do
    {:ok, res} =
      db(:user_docs)
      |> contains(email: res.email)
      |> delete
      |> TestDb.run()

    assert length(res) > 0
  end

  test "select works with filter", %{res: res} do
    {:ok, return} =
      db(:user_docs)
      |> contains(email: res.email)
      |> TestDb.first()

    assert return.email == res.email
  end

  test "select works with string criteria", %{res: res} do
    {:ok, return} =
      db(:user_docs)
      |> filter("body -> 'email' = $1", res.email)
      |> TestDb.first()

    assert return.email == res.email
  end

  test "select works with basic criteria", %{res: _res} do
    {:ok, return} =
      db(:user_docs)
      |> filter(:money_spent, ">", 100)
      |> TestDb.run()

    assert length(return) > 0
  end

  test "select works with existence operator", %{res: res} do
    {:ok, return} =
      db(:user_docs)
      |> exists(:pets, "poopy")
      |> TestDb.first()

    assert return.id == res.id
  end

  test "setting search fields works" do
    new_doc = %{sku: "stuff", name: "Chicken Wings", description: "duck dog lamb"}

    db(:monkies)
    |> searchable([:name, :description])
    |> TestDb.save(new_doc)
  end

  test "select works with sort limit offset" do
    {:ok, return} =
      db(:user_docs)
      |> exists(:pets, "poopy")
      |> sort(:money_spent)
      |> limit(1)
      |> offset(0)
      |> TestDb.first()

    assert return
  end

  test "full text search works" do
    {:ok, res} =
      db(:monkies)
      |> search("duck")
      |> TestDb.run()

    assert length(res) > 0
  end

  test "full text search on the fly works" do
    {:ok, res} =
      db(:monkies)
      |> search(for: "duck", in: [:name, :description])
      |> TestDb.run()

    assert length(res) > 0
  end

  test "single returns nil when no match" do
    {:ok, res} =
      db(:monkies)
      |> contains(email: "dog@dog.comdog")
      |> TestDb.first()

    assert res == nil
  end

  test "finds by id", %{res: res} do
    monkey =
      db(:user_docs)
      |> TestDb.find(res.id)

    case monkey do
      {:error, err} -> raise err
      {:ok, steve} -> assert steve.id == res.id
    end
  end
end
