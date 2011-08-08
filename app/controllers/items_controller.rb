class ItemsController < ApplicationController
  
  def index
    @items = Item.all.page params[:page]
  end
  
  def show
    @item = Item.find_by_slug params[:id]
  end
  
end
