require 'spec_helper'

require_relative '../../lib/bhl/login'

include BHL::Login
describe CollectionsController do
  render_views
  describe "add book" do
    before(:each) do
      truncate_table(ActiveRecord::Base.connection, "books", {})
      truncate_table(ActiveRecord::Base.connection, "volumes", {})
      truncate_table(ActiveRecord::Base.connection, "collections", {})
      truncate_table(ActiveRecord::Base.connection, "book_collections", {})
      doc_test_first = {:vol_jobid => "123", :bok_bibid => "456"}
      doc_test_first[:bok_title] = "Test Book First"

      solr = RSolr.connect :url => SOLR_BOOKS_METADATA
      solr.delete_by_query('*:*')
      solr.commit
      solr.add doc_test_first
      solr.commit
      User.gen() unless User.first
      @user = User.first
      @book = Book.gen(:title => 'Test Book First', :bibid => '456')
      @vol = Volume.gen(:book => @book, :job_id => '123', :get_thumbnail_fail => 0)
      @collection = Collection.gen(:user => @user, :title => "title", :description => "description")
    end

    # using rescue or some other methods to catch error actually catch it but it doesn't continue exceution in the code

    #    describe "add book to new collection" do
    #      it "should create new collection" do
    #        begin
    #          lambda do
    #            get :add_book, :title => "title", :description => "description", :public => "on", :col_id => nil, :vol_id => 123
    #          end.should change(Collection, :count).by(1)
    #        rescue ActionView::MissingTemplate
    #        end
    #      end
    #
    #      it "should create new collection and add book to it" do
    #        begin
    #          lambda do
    #            get :add_book, :title => "title", :description => "description", :public => "on", :col_id => nil, :vol_id => 123
    #          end.should change(BookCollection, :count).by(1)
    #          rescue ActionView::MissingTemplate
    #        end
    #      end
    #
    #      it "should create new collection with the right parameters" do
    #        begin
    #          get :add_book, :title => "title", :description => "description", :public => "on", :col_id => nil, :vol_id => 123
    #          rescue ActionView::MissingTemplate
    #          Collection.last.title.should == "title"
    #          Collection.last.status.should == true
    #          Collection.last.description.should == "description"
    #        end
    #      end
    #
    #      it "should refuse new collection with no title" do
    #        begin
    #          lambda do
    #            get :add_book, :title => "", :description => "description", :public => "on", :col_id => nil, :vol_id => 123
    #          end.should_not change(Collection, :count)
    #        rescue ActionView::MissingTemplate
    #        end
    #      end
    #    end

    describe "add book to pre exist collection" do
      it "should create a new BookCollection" do
        begin
          lambda do
            get :add_book, :col_id => @collection.id, :vol_id => 123
          end.should_not change(Collection, :count).by(1)
        rescue ActionView::MissingTemplate
        end
      end
      it "should create a new BookCollection with ight order" do
        begin
          get :add_book, :col_id => @collection.id, :vol_id => 123
        rescue ActionView::MissingTemplate
          BookCollection.last.position.should == 1
        end
      end
    end
  end

  describe "manage collections" do
    before(:each) do
      truncate_table(ActiveRecord::Base.connection, "users", {})
      User.gen() unless User.first
      @user = User.first
      @other_user = User.gen

      truncate_table(ActiveRecord::Base.connection, "books", {})
      truncate_table(ActiveRecord::Base.connection, "volumes", {})
      @book_test_first = Book.gen(:title => 'Test Book First', :bibid => '456')
      @vol_first = Volume.gen(:book => @book_test_first, :job_id => '1', :get_thumbnail_fail => 0)
      @vol_second = Volume.gen(:book => @book_test_first, :job_id => '2', :get_thumbnail_fail => 0)
      @vol_third = Volume.gen(:book => @book_test_first, :job_id => '3', :get_thumbnail_fail => 0)

      truncate_table(ActiveRecord::Base.connection, "collections", {})
      @my_private_collection = Collection.create(:user_id => @user.id, :title => "my private collection",:description => "description", :updated_at => Date.today, :status => false)
      @my_public_collection = Collection.create(:user_id => @user.id, :title => "my public collection",:description => "description", :updated_at => Date.today, :status => true)
      @other_public_collection = Collection.create(:user_id => @other_user.id, :title => "other private collection",:description => "description", :updated_at => Date.today, :status => true)

      truncate_table(ActiveRecord::Base.connection, "book_collections", {})
      @book_in_my_private_collection = BookCollection.create(:collection_id => @my_private_collection.id, :volume_id => @vol_first.id, :position => 1)
      @second_book_in_my_private_collection = BookCollection.create(:collection_id => @my_private_collection.id, :volume_id => @vol_second.id, :position => 2)
      @third_book_in_my_private_collection = BookCollection.create(:collection_id => @my_private_collection.id, :volume_id => @vol_third.id, :position => 3)

      @book_in_my_public_collection = BookCollection.create(:collection_id => @my_public_collection.id, :volume_id => @vol_first.id, :position => 1)
      @second_book_in_my_public_collection = BookCollection.create(:collection_id => @my_public_collection.id, :volume_id => @vol_second.id, :position => 2)
      @third_book_in_my_public_collection = BookCollection.create(:collection_id => @my_public_collection.id, :volume_id => 3, :position => 3)

      @book_in_other_collection = BookCollection.create(:collection_id => @other_public_collection.id, :volume_id => @vol_first.id, :position => 1)
      @second_book_in_other_collection = BookCollection.create(:collection_id => @other_public_collection.id, :volume_id => @vol_second.id, :position => 2)
      @third_book_in_other_collection = BookCollection.create(:collection_id => @other_public_collection.id, :volume_id => @vol_third.id, :position => 3)

    end

    describe "list books in collections" do

      describe "open my private collection" do
        
        describe "list books in private collection fail" do
          it "should not display show collection page for unsigned user" do
          get :show, :id => @my_private_collection
          response.should redirect_to("/users/login")
          end
          
          it "should not display show private collection page for unauthenticated user" do
            log_in(@other_user)
           get :show, :id => @my_private_collection
           response.should redirect_to("/collections")
          end
        end
        describe "list books in private collection success" do
          before(:each) do
            log_in(@user)
          end

        it "should list all books in my private collection" do
          get :show, :id => @my_private_collection
          response.should have_selector('div', :class => "count", :content =>3.to_s)
        end

        it "should have an open link for each book in my private collection" do
          get :show, :id => @my_private_collection
          response.should have_selector('a', :href => "/books/#{@vol_first.id}/read")
          response.should have_selector('a', :href => "/books/#{@vol_second.id}/read")
          response.should have_selector('a', :href => "/books/#{@vol_third.id}/read")
        end

        it "should have a brief link for each book in my private collection" do
          get :show, :id => @my_private_collection
          response.should have_selector('a', :href => "/books/#{@vol_first.id}/brief")
          response.should have_selector('a', :href => "/books/#{@vol_second.id}/brief")
          response.should have_selector('a', :href => "/books/#{@vol_third.id}/brief")
        end

        it "should display order for each book in my private collection" do
          get :show, :id => @my_private_collection
          response.should have_selector('h5', :content => 1.to_s)
          response.should have_selector('h5', :content => 2.to_s)
          response.should have_selector('h5', :content => 3.to_s)
        end

        it "should display sort links for each book in my private collection" do
          get :show, :id => @my_private_collection
          response.should have_selector('a', :href => "/collections/move_down/#{@book_in_my_private_collection.id}")
          response.should have_selector('a', :href => "/collections/move_up/#{@second_book_in_my_private_collection.id}")
          response.should have_selector('a', :href => "/collections/move_down/#{@second_book_in_my_private_collection.id}")
          response.should have_selector('a', :href => "/collections/move_up/#{@third_book_in_my_private_collection.id}")
        end

        it "should have a delete link for each book in my private collection" do
          get :show, :id => @my_private_collection
          response.should have_selector('a', :href => "/collections/delete_book/#{@book_in_my_private_collection.id}")
          response.should have_selector('a', :href => "/collections/delete_book/#{@second_book_in_my_private_collection.id}")
          response.should have_selector('a', :href => "/collections/delete_book/#{@third_book_in_my_private_collection.id}")
        end

        it "should have pagination bar" do
          truncate_table(ActiveRecord::Base.connection, "book_collections", {})
          20.times { |i| BookCollection.create(:collection_id => @my_private_collection.id, :volume_id => @vol_first.id, :position => i)}
          get :show, :id => @my_private_collection
          response.should have_selector('ul', :class => "pagination")
          truncate_table(ActiveRecord::Base.connection, "book_collections", {})
        end

        describe "delete book from collection" do
          it "should delete book from collection" do
            request.env["HTTP_REFERER"] = "/collections/show/#{@my_private_collection.id}"
            lambda do
              get :delete_book, :book_collection_id => @second_book_in_my_private_collection
              response.should redirect_to("/collections/show/#{@my_private_collection.id}")
              @third_book_in_my_private_collection.position == 2
            end.should change(BookCollection, :count).by(-1)
          end
        end

        describe "sort books in collection" do
          it "should change book order to higher order" do
            request.env["HTTP_REFERER"] = "/collections/show/#{@my_private_collection.id}"
            get :move_up, :book_collection_id => @second_book_in_my_private_collection
            response.should redirect_to("/collections/show/#{@my_private_collection.id}")
            @second_book_in_my_private_collection.position == 1
            @book_in_my_private_collection.position == 2
          end

          it "should change book order to lower order" do
            request.env["HTTP_REFERER"] = "/collections/show/#{@my_private_collection.id}"
            get :move_down, :book_collection_id => @second_book_in_my_private_collection
            response.should redirect_to("/collections/show/#{@my_private_collection.id}")
            @second_book_in_my_private_collection.position == 3
            @third_book_in_my_private_collection.position == 2
          end
        end
      end
      end
      describe "open my public collection" do
        before(:each) do
          log_in(@user)
        end

        it "should list all books in my private collection" do
          get :show, :id => @my_public_collection
          response.should have_selector('div', :class => "count", :content =>3.to_s)
        end

        it "should have an open link for each book in my public collection" do
          get :show, :id => @my_public_collection
          response.should have_selector('a', :href => "/books/#{@vol_first.id}/read")
          response.should have_selector('a', :href => "/books/#{@vol_second.id}/read")
          response.should have_selector('a', :href => "/books/#{@vol_third.id}/read")
        end

        it "should have a brief link for each book in my public collection" do
          get :show, :id => @my_public_collection
          response.should have_selector('a', :href => "/books/#{@vol_first.id}/brief")
          response.should have_selector('a', :href => "/books/#{@vol_second.id}/brief")
          response.should have_selector('a', :href => "/books/#{@vol_third.id}/brief")
        end

        it "should display order for each book in my public collection" do
          get :show, :id => @my_public_collection
          response.should have_selector('h5', :content => 1.to_s)
          response.should have_selector('h5', :content => 2.to_s)
          response.should have_selector('h5', :content => 3.to_s)
        end

        it "should display sort links for each book in my public collection" do
          get :show, :id => @my_public_collection
          response.should have_selector('a', :href => "/collections/move_down/#{@book_in_my_public_collection.id}")
          response.should have_selector('a', :href => "/collections/move_up/#{@second_book_in_my_public_collection.id}")
          response.should have_selector('a', :href => "/collections/move_down/#{@second_book_in_my_public_collection.id}")
          response.should have_selector('a', :href => "/collections/move_up/#{@third_book_in_my_public_collection.id}")
        end

        it "should have a delete link for each book in my public collection" do
          get :show, :id => @my_public_collection
          response.should have_selector('a', :href => "/collections/delete_book/#{@book_in_my_public_collection.id}")
          response.should have_selector('a', :href => "/collections/delete_book/#{@second_book_in_my_public_collection.id}")
          response.should have_selector('a', :href => "/collections/delete_book/#{@third_book_in_my_public_collection.id}")
        end

        it "should have pagination bar" do
          truncate_table(ActiveRecord::Base.connection, "book_collections", {})
          20.times { |i| BookCollection.create(:collection_id => @my_public_collection.id, :volume_id => @vol_first.id, :position => i)}
          get :show, :id => @my_public_collection
          response.should have_selector('ul', :class => "pagination")
          truncate_table(ActiveRecord::Base.connection, "book_collections", {})
        end

        describe "delete book from collection" do
          it "should delete book from collection" do
            request.env["HTTP_REFERER"] = "/collections/show/#{@my_public_collection.id}"
            lambda do
              get :delete_book, :book_collection_id => @second_book_in_my_public_collection
              response.should redirect_to("/collections/show/#{@my_public_collection.id}")
              @third_book_in_my_public_collection.position == 2
            end.should change(BookCollection, :count).by(-1)
          end
        end

        describe "sort books in collection" do
          it "should change book order to higher order" do
            request.env["HTTP_REFERER"] = "/collections/show/#{@my_public_collection.id}"
            get :move_up, :book_collection_id => @second_book_in_my_public_collection
            response.should redirect_to("/collections/show/#{@my_public_collection.id}")
            @second_book_in_my_public_collection.position == 1
            @book_in_my_public_collection.position == 2
          end

          it "should change book order to lower order" do
            request.env["HTTP_REFERER"] = "/collections/show/#{@my_public_collection.id}"
            get :move_down, :book_collection_id => @second_book_in_my_public_collection
            response.should redirect_to("/collections/show/#{@my_public_collection.id}")
            @second_book_in_my_public_collection.position == 3
            @third_book_in_my_public_collection.position == 2
          end
        end
      end

      describe "open other public collection" do

        it "should list all books in other private collection" do
          get :show, :id => @other_public_collection
          response.should have_selector('div', :class => "count", :content =>3.to_s)
        end

        it "should have an open link for each book in other public collection" do
          get :show, :id => @other_public_collection
          response.should have_selector('a', :href => "/books/#{@vol_first.id}/read")
          response.should have_selector('a', :href => "/books/#{@vol_second.id}/read")
          response.should have_selector('a', :href => "/books/#{@vol_third.id}/read")
        end

        it "should have a brief link for each book in other public collection" do
          get :show, :id => @other_public_collection
          response.should have_selector('a', :href => "/books/#{@vol_first.id}/brief")
          response.should have_selector('a', :href => "/books/#{@vol_second.id}/brief")
          response.should have_selector('a', :href => "/books/#{@vol_third.id}/brief")
        end

        it "should display order for each book in other public collection" do
          get :show, :id => @other_public_collection
          response.should have_selector('h5', :content => 1.to_s)
          response.should have_selector('h5', :content => 2.to_s)
          response.should have_selector('h5', :content => 3.to_s)
        end

        it "should have pagination bar" do
          truncate_table(ActiveRecord::Base.connection, "book_collections", {})
          20.times { |i| BookCollection.create(:collection_id => @other_public_collection.id, :volume_id => @vol_first.id, :position => i)}
          get :show, :id => @other_public_collection
          response.should have_selector('ul', :class => "pagination")
          truncate_table(ActiveRecord::Base.connection, "book_collections", {})
        end
      end
    end

    describe "destroy collection" do
      it "should destroy my private collection" do
        log_in(@user)
        request.env["HTTP_REFERER"] = "/users/#{@user.id}/collections"
        lambda do
          get :destroy_collection, :id => @my_private_collection
          response.should redirect_to("/users/#{@user.id}/collections")
        end.should change(Collection, :count).by(-1)
      end

      it "should destroy my public collection" do
        log_in(@user)
        request.env["HTTP_REFERER"] = "/users/#{@user.id}/collections"
        lambda do
          get :destroy_collection, :id => @my_public_collection
          response.should redirect_to("/users/#{@user.id}/collections")
        end.should change(Collection, :count).by(-1)
      end

      it "should not destroy a collection if the user not signed in" do
        request.env["HTTP_REFERER"] = "/users/#{@user.id}/collections"
        lambda do
          get :destroy_collection, :id => @my_private_collection
          response.should redirect_to("/users/login")
        end.should_not change(Collection, :count)
      end
      
      it "should not destroy a collection owned by another user" do
        log_in(@other_user)
        request.env["HTTP_REFERER"] = "/collections"
        lambda do
          get :destroy_collection, :id => @my_private_collection
          response.should redirect_to("/collections")
        end.should_not change(Collection, :count)
      end
    end

    describe "edit collection" do
      
      before(:each) do
        log_in(@user)
      end

      it "should have an option to edit collection title" do
        get :edit, :id => @my_private_collection
        response.should have_selector('label', :content => "Title")
        response.should have_selector('input', :value => "my private collection")
      end

      it "should have an option to edit collection description" do
        get :edit, :id => @my_private_collection
        response.should have_selector('label', :content => "Description")
        response.should have_selector('textarea', :content => "description")
      end

      it "should have an option to edit collection status" do
        get :edit, :id => @my_private_collection
        response.should have_selector('input', :value => "0")
      end

      it "should have an option to upload an image for a collection" do
        get :edit, :id => @my_private_collection
        response.should have_selector('input', :type => "file")
      end

      describe "update fail" do
        before(:each) do
          @attr={:user_id => @user.id, :title => "",:description => "", :updated_at => Date.today, :status => false}
        end
        it "should enter title for collection" do
          request.env["HTTP_REFERER"] = "/collections/edit/#{@my_private_collection.id}"
          @my_private_collection [:title] = ""
          post :update, :id => @my_private_collection, :collection => @attr
          response.should render_template('edit')
        end
      end
      describe "update success" do
        before(:each) do
          @attr={:user_id => @user.id, :title => "my private collection",:description => "description", :updated_at => Date.today, :status => false}
        end
        it "should edit collection with vaild params " do
          request.env["HTTP_REFERER"] = "/users/#{@user.id}/collections"
          post :update, :id => @my_private_collection, :collection => @attr
          response.should redirect_to("/users/#{@user.id}/collections")
        end
      end
    end

    describe "show collection" do
      
      describe "show fail" do
        it "should not display show collection page for unsigned user" do
        get :show, :id => @my_private_collection
        response.should redirect_to("/users/login")
        end
        
        it "should not display show private collection page for unauthenticated user" do
          log_in(@other_user)
         get :show, :id => @my_private_collection
         response.should redirect_to("/collections")
        end
      end
      describe "show success" do
        before(:each) do
          log_in(@user)
        end

      it "should display collection title" do
        get :show, :id => @my_private_collection
        response.should have_selector('b', :content => "Collection Title")
        #response.should have_content("my private collection")
      end

      it "should display collection description" do
        get :show, :id => @my_private_collection
        response.should have_selector('b', :content => "Collection Description")
        #response.should have_content("description")
      end

      it "should display collection status" do
        get :show, :id => @my_private_collection
        response.should have_selector('b', :content => "Status")
        #response.should have_content("Private")
      end

      it "should display edit collection link for collection owned by current user" do
        get :show, :id => @my_private_collection
        response.should have_selector('a', :href => "/collections/edit/#{@my_private_collection.id}", :content => "Edit Collection")
      end
      end
    end
  end

  describe "get 'index'" do
    before(:each) do
      truncate_table(ActiveRecord::Base.connection, "users", {})
      User.gen() unless User.first
      @user = User.first
      log_in(@user)
      @other_user = User.gen

      truncate_table(ActiveRecord::Base.connection, "collections", {})
      @my_private_collection = Collection.create(:user_id => @user.id, :title => "my private collection",:description => "description", :updated_at => "2013-11-20 ", :status => false)
      @my_public_collection = Collection.create(:user_id => @user.id, :title => "my public collection",:description => "description", :updated_at => "2013-11-19 ", :status => true)
      @other_private_collection = Collection.create(:user_id => @other_user.id, :title => "other private collection",:description => "description", :updated_at => "2013-11-18 ", :status => false)
      @other_public_collection = Collection.create(:user_id => @other_user.id, :title => "other public collection",:description => "description", :updated_at => "2013-11-17 ", :status => true)

    end
    describe "list collections" do
      it "should listall public collections" do
        get :index
        response.should have_selector('div', :class => "count", :content =>2.to_s)
      end

      it "should have an open link for public collections" do
        get :index
        response.should have_selector('a', :href => "/collections/show/#{@other_public_collection.id}", :content =>@other_public_collection.title)
        response.should have_selector('a', :href => "/collections/show/#{@my_public_collection.id}", :content =>@my_public_collection.title)
      end

      it "should have last modified date for public collections of ther user" do
        get :index
        response.should have_selector('h5', :content =>"2013-11-17")
        response.should have_selector('h5', :content =>"2013-11-19")
      end

      it "should have pagination bar" do
        truncate_table(ActiveRecord::Base.connection, "collections", {})
        20.times {Collection.create(:user_id => @other_user.id, :title => "other collection",:description => "description", :updated_at => "2013-11-20 ", :status => true)}
        get :index
        response.should have_selector('ul', :class => "pagination")
        truncate_table(ActiveRecord::Base.connection, "collections", {})
      end

      it "should have an open link for each collection" do
        get :index
        response.should have_selector('a', :href => "/collections/show/#{@other_public_collection.id}", :content =>@other_public_collection.title)
        response.should have_selector('a', :href => "/collections/show/#{@my_public_collection.id}", :content =>@my_public_collection.title)
      end
      it "should have last modified date for each collection" do
        get :index
        response.should have_selector('h5', :content =>"2013-11-17")
        response.should have_selector('h5', :content =>"2013-11-19")
      end
      it "should have an image for each collection" do
        get :index
        response.should have_selector('a>img', :src => "/images_en/defaultCollection.jpg")
      end

      it "should have an meta data link for each collection" do
        get :index
        response.should have_selector('a', :href => "/collections/show/#{@other_public_collection.id}")
        response.should have_selector('a', :href => "/collections/show/#{@my_public_collection.id}")
      end

      it "should have delete link for the collections owned by the current user" do
        get :index
        response.should have_selector('a', :href => "/collections/destroy_collection/#{@my_public_collection.id}")
      end

      it "should have search bar" do
        get :index
        response.should have_selector('div', :class => "searchtitle")
        response.should have_selector('input', :id => "searchfield")
      end

      it "should search for collections by title" do
        get :index, :params => {"_title" => "collection"}
        response.should have_selector('div', :class => "count", :content =>2.to_s)
      end

      it "should search for collections by title" do
        get :index, :_title =>  "other _AND collection"
        response.should have_selector('div', :class => "count", :content =>1.to_s)
      end

      it "should have sort features" do
        get :index
        response.should have_selector('a', :href => "/collections?view=title+DESC")
        response.should have_selector('a', :href => "/collections?view=title+ASC")
      end

    end
  end

  describe "list comments for a book" do

    before(:each) do
      truncate_table(ActiveRecord::Base.connection, "comments", {})
      truncate_table(ActiveRecord::Base.connection, "collections", {})
      truncate_table(ActiveRecord::Base.connection, "users", {})
      User.gen() unless User.first
      @user = User.first
      @other_user = User.gen

      @collection = Collection.create(:user_id => @user.id, :title => "collection",:description => "description", :updated_at => Date.today, :status => true)
      @appropriate_collection_comment = Comment.create(:user_id => @user.id, :volume_id => nil, :collection_id => @collection.id, :comment_id => nil, :text => "reply on first book comment")
      @reply_of_appropriate_collection_comment = Comment.create(:user_id => @user.id, :volume_id => nil, :collection_id => @collection.id, :comment_id => @appropriate_collection_comment.id, :text => "first book comment")
      @inappropriate_collection_comment = Comment.create(:user_id => @user.id, :volume_id => nil, :collection_id => @collection.id, :comment_id => nil, :text => "second book comment", :number_of_marks => 2)
      @appropriate_collection_comment_without_replies = Comment.create(:user_id => @user.id, :volume_id => nil, :collection_id => @collection.id, :comment_id => nil, :text => "book comment")
    end

    it "should list all comments and replies of a book" do
      get :show, :id => @collection
      response.should have_selector("span", :id => "comment#{@appropriate_collection_comment.id}")
      response.should have_selector("h4", :content => @appropriate_collection_comment.text)
      response.should have_selector("span", :id => "comment#{@reply_of_appropriate_collection_comment.id}")
      response.should have_selector("h4", :content => @reply_of_appropriate_collection_comment.text)
      response.should have_selector("span", :id => "comment#{@appropriate_collection_comment_without_replies.id}")
      response.should have_selector("h4", :content => @appropriate_collection_comment_without_replies.text)

    end

    it "should show message for inappropriate comments with show link" do
      get :show, :id => @collection
      response.should have_selector("span", :id => "abuse#{@inappropriate_collection_comment.id}")
      response.should have_selector("p", :content => I18n.t(:hidden_comment_msg))
      response.should have_selector("a", :content => "show")
    end

    it "should have a button for each comment or a reply to it as inappropriate " do
      get :show, :id => @collection
      response.should have_selector("input", :type => "button", :id => "mark#{@appropriate_collection_comment.id}")
      response.should have_selector("input", :type => "button", :id => "mark#{@reply_of_appropriate_collection_comment.id}")
      response.should have_selector("input", :type => "button", :id => "mark#{@appropriate_collection_comment_without_replies.id}")
    end

    it "should display comment delete link only for owner of the comment or reply" do
      log_in(@user)
      get :show, :id => @collection
      response.should have_selector("a", :href => "/comments/delete?id=#{@reply_of_appropriate_collection_comment.id}")
      response.should have_selector("a", :href => "/comments/delete?id=#{@appropriate_collection_comment_without_replies.id}")
    end

    it "should not display comment delete link only for owner of the comment or reply" do
      log_in(@other_user)
      get :show, :id => @collection
      response.should_not have_selector("a", :href => "/comments/delete?id=#{@reply_of_appropriate_collection_comment.id}")
      response.should_not have_selector("a", :href => "/comments/delete?id=#{@appropriate_collection_comment_without_replies.id}")
    end

    it "should not display comment delete link for comments having replies" do
      log_in(@user)
      get :show, :id => @collection
      response.should_not have_selector("a", :href => "/comments/delete?id=#{@appropriate_collection_comment.id}")
    end

    it "should display form for craeting new comment when user is signed in" do
      log_in(@user)
      get :show, :id => @collection
      response.should have_selector("form", :id => "new_comment")
    end

    it "should not display form for craeting new comment when user is not signed in" do
      get :show, :id => @collection
      response.should_not have_selector("form", :id => "new_comment")
    end

#    it "should have pagination bar" do
#      truncate_table(ActiveRecord::Base.connection, "comments", {})
#      20.times { |i| Comment.create(:user_id => @user.id, :volume_id => nil, :collection_id => @collection.id, :comment_id => nil, :text => "comment")}
#      get :show, :id => @collection
#      response.should have_selector('ul', :class => "pagination")
#      truncate_table(ActiveRecord::Base.connection, "comments", {})
#    end

  end
end