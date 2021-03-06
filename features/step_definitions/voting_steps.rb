When /^I click on the (left|right) choice$/ do |side|
  css = ".#{side}side"
  vote_count = find('#votes_count')
  prev_vote_count = vote_count.text.to_i if vote_count

  begin
    has_css?(css)
    find(css).click
  rescue Selenium::WebDriver::Error::StaleElementReferenceError
    has_css?(css)
    find(css).click
  end

  if vote_count
    wait_until {vote_count.text.to_i > prev_vote_count }
  end
end

When /^I click on the left photo$/ do
	When "I follow \"leftside\""
end

When /^I click the flag link for the (.*) choice$/ do |side|
	if side == "left"
		When "I follow \"left_flag\""
        else
		When "I follow \"right_flag\""
	end
  sleep 0.4
end

When /^I upload an idea titled '(.*)'$/ do |ideatext|
  When "I click the add new idea button"
	And "I fill in \"new_idea_field\" with \"#{ideatext}\" within \"#the_add_box\""
  has_css?("#submit_btn")
	find("#submit_btn").click
end

When /^I upload an idea titled$/ do |ideatext|
  When "I click the add new idea button"
	And "I fill in \"new_idea_field\" with \"#{ideatext}\" within \"#the_add_box\""
  has_css?("#submit_btn")
	find("#submit_btn").click
end

When /^I click the (.*) button$/ do |button_name|
      case button_name
      when "I can't decide"
        find("#cant_decide_btn").click
        sleep 0.5
      when "I can't decide submit"
        page.evaluate_script('window.alert = function() { return true; }') # prevent javascript alerts from popping up
      	find(".cd_submit_button").click
      when "add new idea"
      	find(".add_idea_button").try(:click)
      when "flag submit"
        page.evaluate_script('window.alert = function() { return true; }')
        find("#flag_inappropriate .flag_submit_button").click
      when "WIDGET flag submit"
        page.evaluate_script('window.alert = function() { return true; }')
      	find(".flag_submit_button").click
      when "photocracy flag submit"
        page.evaluate_script('window.alert = function() { return true; }')
	find(".flag_submit_button").click
      when "add new photo"
      	find("#add_photo_button_for_dialog").click
      when "idea auto activation toggle"
      	find(".toggle_autoactivate_status").click
      end
end

When /^I pick "(.*)"$/ do |radio_label|
	case radio_label 
	when "I like both ideas"
    find('.cd_options .like_both').click
	when "Other"
           When "I choose \"cant_decide_reason_user_other\""
	end
end

When /^I vote (\d*) times$/ do |num_votes|
	num_votes.to_i.times do
		if rand(2) == 1
		   When "I click on the left choice" 
		else
		   When "I click on the right choice"
		end

	end
end

When /^I upload (\d*) ideas$/ do |num_ideas|
	num_ideas.to_i.times do
		When "I upload an idea titled 'test'"
	end
end


Then /^the vote count should be (.*)$/ do |num_votes|
	Then "I should see \"#{num_votes}\" within \"#votes_count\""
end

Then /^the idea count should be (.*)$/ do |num_ideas|
	Then "I should see \"#{num_ideas}\" within \"#item_count\""
end

Then /^there should be only two "Click To Vote" elements$/ do
	Capybara.ignore_hidden_elements = false
  2.should == all(:css, "div.click_to_vote").length
end

Then /^I should see a javascript alert$/ do

	Capybara.driver.is_alert_present.should be_true
end

Then /^the notification in the tell me area should contain links$/ do
	page.should have_css('.tellmearea a')
end

Then /^the notification in the tell me area should not contain links$/ do
	page.should_not have_css('.tellmearea a')
end

Given /^I save the current (.*) (choices|choice|photos)?$/ do |side,type|
	puts "the type is #{type}"
	if type == "photos"
	   @photocracy_mode = true
           set_active_resource_credentials
	end
	if @photocracy_mode
	   Capybara.ignore_hidden_elements = false
	   @question_id = page.locate('#choose_file')[:question_id].to_i
	   Capybara.ignore_hidden_elements = true 
	else
	   @question_id = page.locate('#leftside')[:"data-question_id"].to_i
	end
	
	@earl = Earl.find_by_question_id(@question_id)
        begin
	  @prompt_id = page.locate('#prompt_id').value
	  #The above doesn't work with selenium, for some unknown reason. Fall back to using jquery: 
	rescue 
          @prompt_id = page.evaluate_script("$('#prompt_id').val()").to_i
	end
	if @prompt_id.blank?
	  raise Capybara::ElementNotFound
	end

        @prompt = Prompt.find(@prompt_id, :params => {:question_id => @question_id})

	if side == "left" or side == "two"
          @left_choice = Choice.find(@prompt.left_choice_id, :params => {:question_id => @question_id})
	end
	if side == "right" or side == "two"
          @right_choice = Choice.find(@prompt.right_choice_id, :params => {:question_id => @question_id})
	end
end

Then /^the saved left choice should not be active$/ do
	@left_choice.reload
	@left_choice.should_not be_active
end

Given /^I save the current appearance lookup?$/ do 
	#The above doesn't work with selenium, for some unknown reason. Fall back to using jquery: 
        begin
	  @appearance_lookup = page.locate('#appearance_lookup').value
	rescue
          @appearance_lookup = page.evaluate_script("$('#appearance_lookup').val()").to_s
	end
	if @appearance_lookup.blank?
	  raise Capybara::ElementNotFound
	end
end

Then /^the current appearance lookup should (not )?match the saved appearance lookup$/ do |negation|
  begin
	  @new_appearance_lookup = page.locate('#appearance_lookup').value
	rescue
    @new_appearance_lookup = page.evaluate_script("$('#appearance_lookup').val()").to_s
	end
	if @new_appearance_lookup.blank?
	  raise Capybara::ElementNotFound
	end

        if negation.blank?
	   @new_appearance_lookup.should == @appearance_lookup
        else
	   @new_appearance_lookup.should_not == @appearance_lookup
        end
end


Then /^I should see thumbnails of the two saved choices in the voting history area$/ do
	  @first_thumbnail = page.locate('#your_votes li a')
	  @second_thumbnail = page.locate('#your_votes li a:last')

	  @first_url = @first_thumbnail[:href]
	  @second_url = @second_thumbnail[:href]

	  @first_url.should include(question_choice_path(@earl.name, @left_choice.id))
	  @second_url.should include(question_choice_path(@earl.name, @right_choice.id))
end

Then /^I should not see thumbnails of the two saved choices in the voting history area$/ do
	  lambda {page.locate('#your_votes li a')}.should raise_error(Capybara::ElementNotFound)
	  lambda {page.locate('#your_votes li a:last')}.should raise_error(Capybara::ElementNotFound)
end

Then /^the left thumbnail should be a winner$/ do
	page.locate('#your_votes li a img')[:class].should include("winner")
end
Then /^the left thumbnail should be a loser$/ do
	page.locate('#your_votes li a img')[:class].should include("loser")
end

Then /^the right thumbnail should be a loser$/ do
	page.locate('#your_votes li a:last img')[:class].should include("loser")
end
