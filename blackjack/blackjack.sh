# Array Declaration
declare -a deck=(
    "A,A" "2,A" "3,A" "4,A" "5,A" "6,A" "7,A" "8,A" "9,A" "10,A" "J,A" "Q,A" "K,A"
    "A,H" "2,H" "3,H" "4,H" "5,H" "6,H" "7,H" "8,H" "9,H" "10,H" "J,H" "Q,H" "K,H"
    "A,S" "2,S" "3,S" "4,S" "5,S" "6,S" "7,S" "8,S" "9,S" "10,S" "J,S" "Q,S" "K,S"
    "A,C" "2,C" "3,C" "4,C" "5,C" "6,C" "7,C" "8,C" "9,C" "10,C" "J,C" "Q,C" "K,C"
)

declare -a tempDeck=("${deck[@]}")
# Should I go for a array or a simple 3 variables for each player and dealer
# declare -a dealerHand
# declare -a playerHand

# The followin is for variables
dealerHand1=""
dealerHand2=""
dealerHandT=""

playerHand1=""
playerHand2=""
playerHandT=""

stand="false"

# The following function is for dealing card
dealCard(){
# Below is code that allows for removing a card from the pool 

    drawnCardIndex=$((RANDOM % ${#tempDeck[@]}))

# Creates empty index
    unset 'tempDeck["$drawnCardIndex"]'

# Fix for empty indexs; simply shifts every element from empty to the left
# Technically faster than tempDeck="${tempDeck[@]}", don't quote me on this 

    for (i="$drawnCardIndex"; "$i"<="${#tempDeck[@]}" ; i+=1)
    do
        tempDeck[i]=${tempDeck[i + 1]}
    done

    return "$drawnCardIndex"
}

# The following function is for collecting point for respective card
getCardPoint(){
    local point=0 
# Below is a code that gives/collects the corresponding point value of 'picked' card

    pickedCard="${tempDeck["$drawnCardIndex"]}"

    IFS=',' read -r rank suit <<< "$pickedCard"

    case "$rank" in 
# need an if conditinal check for if point is below 11 or over; then respecitve values will be 11 and 1
        "A" ) point+=11;;
        2 ) point+=2;;
        3 ) point+=3;;
        4 ) point+=4;;
        5 ) point+=5;;
        6 ) point+=6;;
        7 ) point+=7;;
        8 ) point+=8;;
        9 ) point+=9;;
        10 ) point+=10;;
        "J" ) point+=10;;
        "Q" ) point+=10;;
        "K" ) point+=10;;
    esac 
}

# The following checks for the blackJack condition of the first two dealt cards
blackJackCheck(){
    local firstDrawn="$1"
    local secondDrawn="$2"

    local firstCard="${tempDeck["$firstDrawn"]}"
    local secondCard="${tempDeck["$secondDrawn"]}"

    read -r rankFst suitFst <<<"$firstCard"
    read -r rankSnd suitSnd <<<"$secondCard"

    if [[ "$rankFst"=~^[A]$ && "$rankSnd"=~^[JQK]$ ]]; then
        return "true"
    elif [[ "$rankFst"=~^[JQK]$ && "$rankSnd"=~^[A]$ ]]; then
        return "true"
    fi
}

# The following checks dealer's blackJack against player's blackjack
blackJackOutcome(){
    local dealerBlackJack="$1"
    local playerBlackJack="$2"

    if [[ "$dealerBlackJack" && "$playerBlackJack" ]]; then
        echo "push"
    elif [[ "$dealerBlackJack" && ! "$playerBlackJack" ]]; then
        echo "dealer"
    elif [[ ! "$dealerBlackJack" && "$playerBlackJack" ]]; then
        echo "player"
    if 
}

# The following is code for simple point checking 
comparePoints(){
    local playerPoint=$($1 % 21)
    local dealerPoint=$($2 % 21)

    if [[ "$playerPoint" -le ]]; then
        echo "Won"
    elif [[ "$dealerPoint">21 ]]; then
        echo "Game Over"
    fi


}



# Main code block
tempDeck=("${deck[@]}")

dealerHand1=dealCard
dealerHand2=dealCard

playerHand1=dealCard
playerHand2=dealCard

dealerBlackJack=blackJackCheck dealerHand1 dealerHand2 
playerBlackJack=blackJackCheck playerHand1 playerHand2

outcome=blackJackOutcome

# Coditional check to end game
if [[ "$outcome"=="dealer" ]]; then
    echo "Dealer won the bet"
elif [[ "$outcome"=="player" ]]; then
    echo "Dealer won the bet"
elif [[ "$outcome"=="push" ]]; then
    echo "Player gets bet back!"
fi 

while [[ "$gameloop" ]]
do 
    tempDeck=("${deck[@]}")

    dealerHand1=dealCard
    dealerHand2=dealCard

    playerHand1=dealCard
    playerHand2=dealCard

    dealerBlackJack=blackJackCheck dealerHand1 dealerHand2 
    playerBlackJack=blackJackCheck playerHand1 playerHand2

    outcome=blackJackOutcome

    # Coditional check to end game
    if [[ "$outcome"=="dealer" ]]; then
        echo "Dealer won the bet"
        gameloop="false"
    elif [[ "$outcome"=="player" ]]; then
        echo "Dealer won the bet"
        gameloop="false"
    elif [[ "$outcome"=="push" ]]; then
        echo "Player gets bet back!"
        gameloop="false"
    fi 

# The following is the loop for stand/hit
    while [[ ! "$stand" ]]
    do

    echo "Stand or hit" choice

    if [[ "$choice"=="Stand" ]]; then
        echo "Player Standing"
        break
    elif [[ "$choice"=="Hit" ]]; then
        echo "Player hit"

        dealerHandT=dealCard
        playerHandT=dealCard

        playerPoint=getCardPoint
        dealerPoint=getCardPoint
        
    fi 
    done
done




