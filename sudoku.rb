require 'sinatra'
require './lib/sudoku'
require './lib/cell'
require './lib/helper'
require 'sinatra/partial'
require 'rack-flash'
use Rack::Flash

set :partial_template_engine, :erb
set :session_secret, "I'm the secret key to sign the cookie"

enable :sessions

def random_sudoku
    seed = (1..9).to_a.shuffle + Array.new(81-9, 0)
    sudoku = Sudoku.new(seed.join)
    sudoku.solve!
    puts sudoku
    sudoku.to_s.chars
end

def puzzle(sudoku)
  test = sudoku.dup # this method is yours to implement
  until test.count(0) == 45 
  test[(0..80).to_a.sample] = 0
  end
  test 
end

get '/' do # default route for our website
   erb :home
end

get '/play' do # default route for our website
  prepare_to_check_solution
  generate_new_puzzle_if_necessary
  @current_solution = session[:current_solution] || session[:puzzle]
  @solution = session[:solution]
  @puzzle = session[:puzzle]
  erb :index
end


get '/new' do
	session.clear
	 sudoku = random_sudoku
  session[:solution] = sudoku
  session[:puzzle] = puzzle(sudoku)
  session[:current_solution] = session[:puzzle]
	new_puzzle
	redirect to("/play")
end

get '/solution' do
  @current_solution = session[:solution]
  @solution = session[:solution]
  @puzzle = session[:puzzle]
  erb :index
end

post '/play' do
  cells = box_order_to_row_order(params["cell"]) 
  session[:current_solution] = cells.map{|value| value.to_i }.join
  session[:check_solution] = true
  redirect to("/play")
end

def generate_new_puzzle_if_necessary
  return if session[:current_solution]
  sudoku = random_sudoku
  session[:solution] = sudoku
  session[:puzzle] = puzzle(sudoku)
  session[:current_solution] = session[:puzzle]    
end

def new_puzzle
  sudoku = random_sudoku
  session[:solution] = sudoku
  session[:puzzle] = puzzle(sudoku)
  session[:current_solution] = session[:puzzle]    
end

def prepare_to_check_solution
  @check_solution = session[:check_solution]
  if @check_solution
    flash[:notice] = "Shitty answers are in yellow mate..."
  end
  session[:check_solution] = nil
end

def box_order_to_row_order(cells)
  boxes = cells.each_slice(9).to_a
  (0..8).to_a.inject([]) {|memo, i|
    first_box_index = i / 3 * 3
    three_boxes = boxes[first_box_index, 3]
    three_rows_of_three = three_boxes.map do |box| 
      row_number_in_a_box = i % 3
      first_cell_in_the_row_index = row_number_in_a_box * 3
      box[first_cell_in_the_row_index, 3]
    end
    memo += three_rows_of_three.flatten
  }
end
