# rails_db_script_helper


This is a single file helper to make your script easy to be written and read. I used it in my daily job.

# Principal


- Single File to apply minimalism
- No dependency except std lib / Rails
- Command Line parameter friendly
- Optional Prompty for opitons
- Confirm before submit transaction


# Example Script


	require File.join(File.dirname(__FILE__), '..', 'db_script_helper')
	
	# if you want to read params
	OptionParser.new do |opts|
	  opts.on("-c", "--company [company_id]", "Company Id") do |company|
	    params[:company] = company
	  end
	end.parse!
	
	# script topic and detail description
	desc "User Fix", "Propose : Fix user data if user is invalid" do 
	
	  # input company id, if passed by parameters, will ignore prompty
	  param :company, "Company ID : ", :required => true
	
	  # you can define different data set to update
	  change_set :invalid_users do
	    #return could be one record or array of record
	    User.find_all_by_company_id params[:company]
	  end
	
	  # update data set you asked
	  update :invalid_users do |rec|
	    rec.is_deleted = true
	  end
	  # it will show all change set and confirm with Y/N
	
	  # a summary is a good change data report
	  summary :invalid_users do |result|
	    puts result
	  end
	end

	
# Execution

	cd rails_app_path
	script/runner example_path.rb [options]

# Example Output

	================================================================================
	                                    User Fix
	================================================================================
	Propose : Fix user data if user is invalid
	================================================================================
	Company ID : 12
	================================================================================
	                                   Processing
	================================================================================
	users : 36
	     +-is_deleted : false -> true
	users : 40
	     +-is_deleted : false -> true
	users : 84
	     +-is_deleted : false -> true
	users : 85
	     +-is_deleted : false -> true
	users : 86
	     +-is_deleted : false -> true
	================================================================================
	[Y]es / [N]o :N
	================================================================================
	                             QUIT without changing
	================================================================================

# Tips

# Authors


Gene Wu



License
=======
MIT
