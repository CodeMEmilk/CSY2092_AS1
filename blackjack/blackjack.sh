```bash

# ============================================================
# BLACKJACK
# ============================================================


# ============================================================
# Game Point Settings
# ============================================================

BASE_POINTS=10
BLACKJACK_BONUS=5
CHARLIE_BONUS=20

playerScore=0


# ============================================================
# Array Declaration
# ============================================================

declare -a deck=(
    "A,A" "2,A" "3,A" "4,A" "5,A" "6,A" "7,A" "8,A" "9,A" "10,A" "J,A" "Q,A" "K,A"
    "A,H" "2,H" "3,H" "4,H" "5,H" "6,H" "7,H" "8,H" "9,H" "10,H" "J,H" "Q,H" "K,H"
    "A,S" "2,S" "3,S" "4,S" "5,S" "6,S" "7,S" "8,S" "9,S" "10,S" "J,S" "Q,S" "K,S"
    "A,C" "2,C" "3,C" "4,C" "5,C" "6,C" "7,C" "8,C" "9,C" "10,C" "J,C" "Q,C" "K,C"
)

declare -a tempDeck
declare -a playerHand
declare -a dealerHand


# ============================================================
# Deal Card
# ============================================================

dealCard()
{
    local drawnCardIndex
    local drawnCard

    drawnCardIndex=$((RANDOM % ${#tempDeck[@]}))

    drawnCard="${tempDeck[$drawnCardIndex]}"

    # Remove dealt card from the deck
    unset 'tempDeck[drawnCardIndex]'

    # Re-index the array
    tempDeck=("${tempDeck[@]}")

    echo "$drawnCard"
}


# ============================================================
# Get Card Point
# ============================================================

getCardPoint()
{
    local card="$1"
    local currentPoint="$2"

    local rank
    local suit
    local point=0

    IFS=',' read -r rank suit <<< "$card"

    case "$rank" in

        A)
            # Ace is worth 11 if adding 11 does not
            # cause the current hand to exceed 21.
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


# ============================================================
# Calculate Hand Total
# ============================================================

calculateHandTotal()
{
    local total=0
    local card
    local point

    for card in "$@"
    do
        point=$(getCardPoint "$card" "$total")

        (( total += point ))
    done

    echo "$total"
}


# ============================================================
# Check Blackjack
# ============================================================

blackJackCheck()
{
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


# ============================================================
# Blackjack Outcome
# ============================================================

blackJackOutcome()
{
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


# ============================================================
# Compare Points
# ============================================================

comparePoints()
{
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


# ============================================================
# Update Player Score
# ============================================================

updateScore()
{
    local outcome="$1"

    case "$outcome" in

        win)
            (( playerScore += BASE_POINTS ))
            echo "You gained $BASE_POINTS points."
            ;;

        blackjack)
            (( playerScore += BASE_POINTS + BLACKJACK_BONUS ))

            echo "Blackjack bonus: +$BLACKJACK_BONUS points."
            echo "You gained $((BASE_POINTS + BLACKJACK_BONUS)) points."
            ;;

        charlie)
            (( playerScore += BASE_POINTS + CHARLIE_BONUS ))

            echo "Five Card Charlie bonus: +$CHARLIE_BONUS points."
            echo "You gained $((BASE_POINTS + CHARLIE_BONUS)) points."
            ;;

        loss)
            (( playerScore -= BASE_POINTS ))

            echo "You lost $BASE_POINTS points."
            ;;

        push)
            echo "Push - no points gained or lost."
            ;;

    esac
}


# ============================================================
# Check Five Card Charlie
# ============================================================

checkCharlie()
{
    local handSize="$1"
    local handPoint="$2"

    if (( handSize == 5 && handPoint <= 21 ))
    then
        return 0
    else
        return 1
    fi
}


# ============================================================
# Main Game Loop
# ============================================================

gameloop="true"

while [[ "$gameloop" == "true" ]]
do

    # ========================================================
    # Reset Deck and Hands
    # ========================================================

    tempDeck=("${deck[@]}")

    playerHand=()
    dealerHand=()


    # ========================================================
    # Initial Deal
    # ========================================================

    dealerHand+=("$(dealCard)")
    dealerHand+=("$(dealCard)")

    playerHand+=("$(dealCard)")
    playerHand+=("$(dealCard)")


    # ========================================================
    # Blackjack Check
    # ========================================================

    dealerBlackJack=$(blackJackCheck \
        "${dealerHand[0]}" \
        "${dealerHand[1]}")

    playerBlackJack=$(blackJackCheck \
        "${playerHand[0]}" \
        "${playerHand[1]}")


    outcome=$(blackJackOutcome \
        "$dealerBlackJack" \
        "$playerBlackJack")


    # ========================================================
    # Initial Display
    # ========================================================

    echo
    echo "========================================"
    echo "              BLACKJACK"
    echo "========================================"

    echo
    echo "Current Points: $playerScore"
    echo

    echo "Dealer: [Hidden] ${dealerHand[1]}"
    echo "Player: ${playerHand[*]}"

    echo
    echo "Cards remaining: ${#tempDeck[@]}"


    # ========================================================
    # Immediate Blackjack Outcomes
    # ========================================================

    if [[ "$outcome" == "dealer" ]]
    then

        echo
        echo "Dealer has Blackjack!"
        echo "Player loses."

        updateScore "loss"


    elif [[ "$outcome" == "player" ]]
    then

        echo
        echo "========================================"
        echo "          NATURAL BLACKJACK!"
        echo "========================================"

        echo "Player has Blackjack!"
        echo "Player wins!"

        updateScore "blackjack"


    elif [[ "$outcome" == "push" ]]
    then

        echo
        echo "Both player and dealer have Blackjack."
        echo "Push - bet returned."

        updateScore "push"


    else

        # ====================================================
        # PLAYER TURN
        # ====================================================

        stand="false"
        charlie="false"

        while [[ "$stand" == "false" ]]
        do

            playerPoint=$(calculateHandTotal "${playerHand[@]}")

            echo
            echo "----------------------------------------"
            echo "Player hand: ${playerHand[*]}"
            echo "Player total: $playerPoint"
            echo "Current points: $playerScore"
            echo "----------------------------------------"


            # ------------------------------------------------
            # Player Bust
            # ------------------------------------------------

            if (( playerPoint > 21 ))
            then
                echo
                echo "Player busts!"
                break
            fi


            # ------------------------------------------------
            # Five Card Charlie
            # ------------------------------------------------

            if checkCharlie "${#playerHand[@]}" "$playerPoint"
            then
                echo
                echo "========================================"
                echo "       FIVE CARD CHARLIE!"
                echo "========================================"

                echo "Player reached five cards without busting."
                echo "Player automatically wins!"

                charlie="true"
                stand="true"

                break
            fi


            # ------------------------------------------------
            # Player Choice
            # ------------------------------------------------

            read -rp "Stand or Hit? " choice


            case "${choice,,}" in

                stand|s)

                    echo "Player stands."
                    stand="true"
                    ;;


                hit|h)

                    echo "Player hits."

                    playerHand+=("$(dealCard)")

                    echo "Card dealt: ${playerHand[-1]}"

                    ;;


                *)

                    echo "Invalid choice."
                    echo "Please enter H/Hit or S/Stand."

                    ;;

            esac

        done


        # ====================================================
        # Five Card Charlie Outcome
        # ====================================================

        if [[ "$charlie" == "true" ]]
        then

            updateScore "charlie"


        else

            # =================================================
            # Calculate Player Total After Player Turn
            # =================================================

            playerPoint=$(calculateHandTotal "${playerHand[@]}")


            # =================================================
            # Player Bust
            # =================================================

            if (( playerPoint > 21 ))
            then

                echo
                echo "Dealer wins because the player busted."

                updateScore "loss"


            else

                # =============================================
                # DEALER TURN
                # =============================================

                echo
                echo "========================================"
                echo "             DEALER TURN"
                echo "========================================"

                echo
                echo "Dealer reveals: ${dealerHand[*]}"

                dealerPoint=$(calculateHandTotal "${dealerHand[@]}")

                echo "Dealer total: $dealerPoint"


                # =============================================
                # Dealer Hits Until 17
                # =============================================

                while (( dealerPoint < 17 ))
                do

                    echo
                    echo "Dealer hits."

                    dealerHand+=("$(dealCard)")

                    dealerPoint=$(calculateHandTotal \
                        "${dealerHand[@]}")

                    echo "Dealer drew: ${dealerHand[-1]}"
                    echo "Dealer total: $dealerPoint"

                done


                # =============================================
                # Dealer Bust
                # =============================================

                if (( dealerPoint > 21 ))
                then

                    echo
                    echo "Dealer busts!"
                    echo "Player wins!"

                    updateScore "win"


                else

                    # =========================================
                    # Final Comparison
                    # =========================================

                    echo
                    echo "========================================"
                    echo "           FINAL RESULT"
                    echo "========================================"

                    echo
                    echo "Player hand: ${playerHand[*]}"
                    echo "Player total: $playerPoint"

                    echo
                    echo "Dealer hand: ${dealerHand[*]}"
                    echo "Dealer total: $dealerPoint"


                    outcome=$(comparePoints \
                        "$playerPoint" \
                        "$dealerPoint")


                    case "$outcome" in

                        player)

                            echo
                            echo "Player wins!"

                            updateScore "win"
                            ;;


                        dealer)

                            echo
                            echo "Dealer wins."

                            updateScore "loss"
                            ;;


                        push)

                            echo
                            echo "Push - both hands have the same value."

                            updateScore "push"
                            ;;

                    esac

                fi

            fi

        fi

    fi


    # ========================================================
    # Round Summary
    # ========================================================

    echo
    echo "========================================"
    echo "            ROUND SUMMARY"
    echo "========================================"

    echo "Player points: $playerScore"


    # ========================================================
    # Continue Game
    # ========================================================

    echo

    read -rp "Play another round? (y/n): " playAgain

    if [[ "${playAgain,,}" != "y" ]]
    then
        gameloop="false"
    fi

done


# ============================================================
# Final Score
# ============================================================

echo
echo "========================================"
echo "             GAME OVER"
echo "========================================"

echo "Final Player Score: $playerScore points"

if (( playerScore > 0 ))
then
    echo "Overall result: Positive score."

elif (( playerScore < 0 ))
then
    echo "Overall result: Negative score."

else
    echo "Overall result: Even score."
fi

echo
echo "Thanks for playing Blackjack!"
```
