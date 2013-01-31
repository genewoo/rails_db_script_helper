require File.join(File.dirname(__FILE__), '..', 'db_script_helper')

# script topic and detail description
desc "User Fix", "Propose : Fix user data if user is invalid" do 

  # require parameter of company id, if passed by parameters, will ignore prompty
  param :company, "Company ID", :required => true

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
