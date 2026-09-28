```bash
# ==========================================
# Array Declaration
# ==========================================

declare -a deck=(
    "A,A" "2,A" "3,A" "4,A" "5,A" "6,A" "7,A" "8,A" "9,A" "10,A" "J,A" "Q,A" "K,A"
    "A,H" "2,H" "3,H" "4,H" "5,H" "6,H" "7,H" "8,H" "9,H" "10,H" "J,H" "Q,H" "K,H"
    "A,S" "2,S" "3,S" "4,S" "5,S" "6,S" "7,S" "8,S" "9,S" "10,S" "J,S" "Q,S" "K,S"
    "A,C" "2,C" "3,C" "4,C" "5,C" "6,C" "7,C" "8,C" "9,C" "10,C" "J,C" "Q,C" "K,C"
)

declare -a tempDeck
declare -a playerHand
declare -a dealerHand


# ==========================================
# Deal Card
# ==========================================

dealCard() {

    local drawnCardIndex
    local drawnCard

    drawnCardIndex=$((RANDOM % ${#tempDeck[@]}))

    drawnCard="${tempDeck[$drawnCardIndex]}"

    # Remove the card from the deck
    unset 'tempDeck[drawnCardIndex]'

    # Re-index the array after removing the card
    tempDeck=("${tempDeck[@]}")

    echo "$drawnCard"
}


# ==========================================
# Get Card Point
# ==========================================

getCardPoint() {

    local card="$1"
    local currentPoint="$2"

    local rank
    local suit
    local point=0

    IFS=',' read -r rank suit <<< "$card"

    case "$rank" in

        A)
            # Ace is worth 11 if adding 11 does not
            # make the current hand exceed 21.
            if (( currentPoint + 11 <= 21 ))
            then
                point=11
            else
                point=1
            fi
            ;;

        2)
            point=2
            ;;

        3)
            point=3
            ;;

        4)
            point=4
            ;;

        5)
            point=5
            ;;

        6)
            point=6
            ;;

        7)
            point=7
            ;;

        8)
            point=8
            ;;

        9)
            point=9
            ;;

        10|J|Q|K)
            point=10
            ;;

    esac

    echo "$point"
}


# ==========================================
# Calculate Hand Total
# ==========================================

calculateHandTotal() {

    local total=0
    local card
    local point

    for card in "$@"
    do
        point=$(getCardPoint "$card" "$total")
        ((total += point))
    done

    echo "$total"
}


# ==========================================
# Blackjack Check
# ==========================================

blackJackCheck() {

    local firstCard="$1"
    local secondCard="$2"

    local rankFst
    local suitFst
    local rankSnd
    local suitSnd

    IFS=',' read -r rankFst suitFst <<< "$firstCard"
    IFS=',' read -r rankSnd suitSnd <<< "$secondCard"

    if [[ "$rankFst" == "A" &&
          "$rankSnd" =~ ^(10|J|Q|K)$ ]]
    then
        echo "true"

    elif [[ "$rankSnd" == "A" &&
            "$rankFst" =~ ^(10|J|Q|K)$ ]]
    then
        echo "true"

    else
        echo "false"
    fi
}


# ==========================================
# Blackjack Outcome
# ==========================================

blackJackOutcome() {

    local dealerBlackJack="$1"
    local playerBlackJack="$2"

    if [[ "$dealerBlackJack" == "true" &&
          "$playerBlackJack" == "true" ]]
    then
        echo "push"

    elif [[ "$dealerBlackJack" == "true" &&
            "$playerBlackJack" == "false" ]]
    then
        echo "dealer"

    elif [[ "$dealerBlackJack" == "false" &&
            "$playerBlackJack" == "true" ]]
    then
        echo "player"

    else
        echo "continue"
    fi
}


# ==========================================
# Compare Points
# ==========================================

comparePoints() {

    local playerPoint="$1"
    local dealerPoint="$2"

    if (( playerPoint > 21 ))
    then
        echo "dealer"

    elif (( dealerPoint > 21 ))
    then
        echo "player"

    elif (( playerPoint > dealerPoint ))
    then
        echo "player"

    elif (( playerPoint < dealerPoint ))
    then
        echo "dealer"

    else
        echo "push"
    fi
}


# ==========================================
# Main Game
# ==========================================

gameloop="true"

while [[ "$gameloop" == "true" ]]
do

    # Reset the deck
    tempDeck=("${deck[@]}")

    # Reset the hands
    playerHand=()
    dealerHand=()


    # ======================================
    # Initial Deal
    # ======================================

    dealerHand+=("$(dealCard)")
    dealerHand+=("$(dealCard)")

    playerHand+=("$(dealCard)")
    playerHand+=("$(dealCard)")


    # ======================================
    # Check for Blackjack
    # ======================================

    dealerBlackJack=$(blackJackCheck \
        "${dealerHand[0]}" \
        "${dealerHand[1]}")

    playerBlackJack=$(blackJackCheck \
        "${playerHand[0]}" \
        "${playerHand[1]}")


    outcome=$(blackJackOutcome \
        "$dealerBlackJack" \
        "$playerBlackJack")


    # ======================================
    # Display Initial Hands
    # ======================================

    echo
    echo "================================"
    echo "          BLACKJACK"
    echo "================================"

    echo
    echo "Dealer: [Hidden] ${dealerHand[1]}"
    echo "Player: ${playerHand[*]}"


    # ======================================
    # Immediate Blackjack Outcome
    # ======================================

    if [[ "$outcome" == "dealer" ]]
    then

        echo
        echo "Dealer has Blackjack!"
        echo "Player loses."

    elif [[ "$outcome" == "player" ]]
    then

        echo
        echo "Player has Blackjack!"
        echo "Player wins!"

    elif [[ "$outcome" == "push" ]]
    then

        echo
        echo "Both player and dealer have Blackjack."
        echo "Push - bet returned."

    else

        # ==================================
        # PLAYER TURN
        # ==================================

        stand="false"

        while [[ "$stand" == "false" ]]
        do

            playerPoint=$(calculateHandTotal "${playerHand[@]}")

            echo
            echo "Player hand: ${playerHand[*]}"
            echo "Player total: $playerPoint"


            # Player has busted
            if (( playerPoint > 21 ))
            then
                echo "Player busts!"
                break
            fi


            read -rp "Stand or Hit? " choice


            case "${choice,,}" in

                stand)
                    echo "Player stands."
                    stand="true"
                    ;;

                hit)
                    echo "Player hits."
                    playerHand+=("$(dealCard)")
                    ;;

                *)
                    echo "Please enter Stand or Hit."
                    ;;

            esac

        done


        # ==================================
        # DEALER TURN
        # ==================================

        playerPoint=$(calculateHandTotal "${playerHand[@]}")


        if (( playerPoint <= 21 ))
        then

            echo
            echo "Dealer reveals: ${dealerHand[*]}"

            dealerPoint=$(calculateHandTotal "${dealerHand[@]}")


            # Dealer must hit below 17
            while (( dealerPoint < 17 ))
            do

                echo "Dealer hits."

                dealerHand+=("$(dealCard)")

                dealerPoint=$(calculateHandTotal "${dealerHand[@]}")

            done


            echo
            echo "Dealer hand: ${dealerHand[*]}"
            echo "Dealer total: $dealerPoint"


            # ==================================
            # Compare Final Scores
            # ==================================

            outcome=$(comparePoints \
                "$playerPoint" \
                "$dealerPoint")


            case "$outcome" in

                player)
                    echo "Player wins!"
                    ;;

                dealer)
                    echo "Dealer wins."
                    ;;

                push)
                    echo "Push - bet returned."
                    ;;

            esac

        else

            echo "Dealer wins because player busted."

        fi

    fi


    # ======================================
    # New Game
    # ======================================

    echo

    read -rp "Play another round? (y/n): " playAgain

    if [[ "${playAgain,,}" != "y" ]]
    then
        gameloop="false"
    fi

done


echo
echo "Thanks for playing Blackjack!"
```
