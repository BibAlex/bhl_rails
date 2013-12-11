class UserSearchHistoryController < ApplicationController
  include BHL::Login
  
  def save_query
    if authenticate_user(params[:user_id].to_i)
      query = Query.new(:user_id => params[:user_id].to_i, :string => params[:query])
      query.save
      flash.now[:notice] = I18n.t(:query_saved)
      flash.keep
      if request.env["HTTP_REFERER"].present? and request.env["HTTP_REFERER"] != request.env["REQUEST_URI"]
        redirect_to :back
      else
        redirect_to :controller => :books, :action => :index
      end
    end
  end

  def delete_query
    query = Query.find(params[:id])
    if authenticate_user(query.user_id)
      query.destroy
      flash.now[:notice]=I18n.t(:query_destroyed)
      flash.keep
      if request.env["HTTP_REFERER"].present? and request.env["HTTP_REFERER"] != request.env["REQUEST_URI"]
        redirect_to :back
      else
        redirect_to :controller => :books, :action => :index
      end
    end
  end

  private

  def authenticate_user(user_id)
    if !is_loggged_in?
      redirect_to :controller => :users, :action => :login
      return false
    end
    if session["user_id"].to_i != user_id
      flash.now[:error] = I18n.t(:access_denied_error)
      flash.keep
      redirect_to :controller => :books, :action => :index
      return false
    end
    return true
  end

end