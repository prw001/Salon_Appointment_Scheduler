#! /bin/bash
PSQL="psql --username=freecodecamp --dbname=salon -t -A -X -c"

MAIN_MENU()
{
  #no arg provided, run this header first upon running the program
  #otherwise echo the arg (message) provided from calling MAIN_MENU()
  if [[ -z $1 ]]
  then
    echo -e "\n~~~~~ MY SALON ~~~~~\n"
    echo -e "Welcome to My Salon, how can I help you?\n"
  else
    echo -e "$1"
  fi

  #Prompt user
  #get options
  #OPTIONS_VALUES=$($PSQL "SELECT service_id, name FROM services")
  AVAILABLE_SERVICES=$($PSQL "SELECT service_id, name FROM services ORDER BY service_id")
  echo "$AVAILABLE_SERVICES" | while IFS="|" read SERVICE_ID SERVICE_NAME
  do
    echo "$SERVICE_ID) $SERVICE_NAME"
  done
  #display options
  #DISPLAY_OPTIONS "$OPTIONS_VALUES"
  #read input
  read SERVICE_ID_SELECTED
  #validate input
  #if valid process input
  if [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]
  then
    MAIN_MENU "\nI could not find that service. What would you like today?"
    return
  fi
  #try get service type
  SERVICE_TYPE="$($PSQL "SELECT name FROM services WHERE service_id=$SERVICE_ID_SELECTED")"
  #if doesn't exist, re-show the options with a message to the user to select a valid option.
  if [[ -z $SERVICE_TYPE ]]
  then
    MAIN_MENU "\nI could not find that service. What would you like today?"
  else
    echo -e "\nWhat's your phone number?"
    read CUSTOMER_PHONE
    #try to find customer in database
    CUSTOMER_NAME="$($PSQL "SELECT name FROM customers WHERE phone='$CUSTOMER_PHONE'")"
    if [[ -z $CUSTOMER_NAME ]]
    then
      echo -e "\nI don't have a record for that phone number, what's your name?"
      read CUSTOMER_NAME
      #once they've supplied their name and number correctly, try to insert into database
      INSERT_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers (phone, name) VALUES ('$CUSTOMER_PHONE', '$CUSTOMER_NAME')")
    fi
    #prompt user for appointment time
    echo -e "\nWhat time would you like your $SERVICE_TYPE, $CUSTOMER_NAME?"
    read SERVICE_TIME
    #Try to add the service appointment
    CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE name='$CUSTOMER_NAME'")
    INSERT_APPOINTMENT_RESULT=$($PSQL "INSERT INTO appointments (customer_id, service_id, time) VALUES ($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME')")
    #let the customer know when appointment succesfully created in the database
    if [[ "$INSERT_APPOINTMENT_RESULT" = "INSERT 0 1" ]]
    then
      echo -e "\nI have put you down for a $SERVICE_TYPE at $SERVICE_TIME, $CUSTOMER_NAME."
    fi
  fi
}

#iterate through options provided in arg list, reformat & print
DISPLAY_OPTIONS()
{
  echo "$1" | while read -r LINE
  do
    if [[ -n "$LINE" ]]
    then
      echo "$LINE" | sed -r 's/([0-9]+)\|([A-Za-z ]+)/\1) \2/'
    fi
  done
}

MAIN_MENU