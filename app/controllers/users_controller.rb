class UsersController < ApplicationController

  # User Signup
  def signup
    loggedOut
    @user = User.new
  end

  def create_user
    @user = User.new(user_params)
    if @user.save
      session[:id] = @user.id
      session[:username] = @user.username
      redirect_to profile_path(@user.id), :notice => "Hello, #{@user.username}!!"
    else
      render "signup"
      flash[:notice] = "Unable to signup!!"
    end
  end

  # User login
  def login
    loggedOut
  end

  def log_user
    user = User.find_by(username: params[:username])
    if user and user.password == params[:password]
      session[:id] = user.id
      session[:username] = user.username
      redirect_to root_path, :notice => "Hello, #{user.username}!!"
    else
      flash[:notice] = "Invalid username or password!!"
      render 'login'
    end
  end

  def logout
    reset_session
    redirect_to login_path, :notice => "You are now logged out!!"
  end

  def profile
    loggedIn
    if is_user_valid(params[:id])

      @user = User.find_by(:id => params[:id])

      if session[:id] != @user.id
        View.create(:view_by => session[:id], :view_to => params[:id])
      end

      @posts = Post.where(:user => @user.id).order(id: :desc)
      @followers = Follow.where(:follow_to => @user.id).count
      @followings = Follow.where(:follow_by => @user.id).count
      @views = View.where(:view_to => @user.id).count

      render 'profile'
    else
      invalid_user
    end
  end

  def deactivate
    loggedIn
    if is_user_valid(params[:id])
      render 'deactivate'
    else
      invalid_user
    end
  end

  def delete_account
    user = session[:id]

    View.where(:view_by => user).destroy_all
    View.where(:view_to => user).destroy_all
    Follow.where(:follow_by => user).destroy_all
    Follow.where(:follow_to => user).destroy_all
    Like.where(:like_by => user).destroy_all

    Post.where(:user => user).each do |post|
      pl = Like.find_by(:post => post.id)
      pl.destroy unless pl == nil
    end

    Post.where(:user => user).destroy_all
    User.find_by(:id => user).destroy

    reset_session
    redirect_to login_path, :notice => "Your account is now deactivated!!"
  end

  private def user_params
    params.require(:user).permit(:username, :email, :password)
  end

end
