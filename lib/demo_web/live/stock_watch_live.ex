defmodule DemoWeb.StockWatchLive do
use DemoWeb, :live_view
alias Phoenix.LiveView.JS
@refresh_rate 250

def mount(_params, _session, socket) do
 if connected?(socket), do: Process.send_after(self(), :tick, @refresh_rate)

 socket =
   socket
   |> assign(
     stocks: %{
       "Aktie A" => 100,
       "Aktie B" => 200,
       "Aktie C" => 300,
       "Aktie D" => 400
     }
   )
   |> assign(portfolio: %{})
   |> assign(balance: 1_000)
   |> assign(portfolio_value: 0)
   |> assign(show_game_rules: false)

 {:ok, socket}
end

def render(assigns) do
 ~H"""
 <table>
   <tbody>
     <tr><td>Barguthaben:</td><td><%= @balance %></td></tr>
     <tr><td>Wert des Portfolios:</td><td><%= @portfolio_value %></td></tr>
     <tr><td>Summe:</td><td><%= @balance + @portfolio_value %></td></tr>
   </tbody>
 </table>
 <table>
   <thead>
     <tr>
       <th>Name</th>
       <th>Preis</th>
       <th>Portfolio</th>
       <th colspan="2"></th>
     </tr>
   </thead>
   <tbody>
   <%= for {stock_name, value} <- @stocks do %>
     <tr>
       <td><%= stock_name %></td>
       <td><%= value %></td>
       <td><%= Map.get(@portfolio, stock_name) %></td>
       <td width="20%">
         <%= if value <= @balance do %>
           <button phx-click="buy" phx-value-ref={stock_name}>Kaufen!</button>
         <% end %>
       </td>
       <td width="20%">
         <%= if match?(%{^stock_name => amount} when amount > 0, @portfolio) do %>
           <button phx-click="sell" phx-value-ref={stock_name}>Verkaufen!</button>
         <% end %>
       </td>
     </tr>
   <% end %>
   </tbody>
 </table>

 <%= if @show_game_rules == false do %>
   <button phx-click="game_rules">Spielregeln anzeigen</button>
 <% end %>

 <%= if @show_game_rules == true do %>
   <div id="modal" class="phx-modal" phx-remove={hide_modal()}>
     <div
       id="modal-content"
       class="phx-modal-content"
       phx-click-away={hide_modal()}
       phx-window-keydown={hide_modal()}
       phx-key="escape"
     >
       <button class="phx-modal-close" phx-click={hide_modal()}>✖</button>
       <p>Spielregeln. Beispiel Inhalt.</p>
     </div>
   </div>
 <% end %>
 """
end

def handle_info(:tick, socket) do
 Process.send_after(self(), :tick, @refresh_rate)

 {:noreply, update_stock_prices(socket)}
end

def handle_event("buy", %{"ref" => stock_name}, socket) do
 {:noreply, execute_order(stock_name, 1, socket)}
end

def handle_event("sell", %{"ref" => stock_name}, socket) do
 {:noreply, execute_order(stock_name, -1, socket)}
end

def handle_event("game_rules", _, socket) do
 {:noreply, assign(socket, show_game_rules: true)}
end

def handle_event("clicked", _, socket) do
 {:noreply, assign(socket, show_game_rules: false)}
end

def hide_modal(js \\ %JS{}) do
 js
 |> JS.hide(transition: "fade-out", to: "#modal")
 |> JS.hide(transition: "fade-out-scale", to: "#modal-content")
 |> JS.push("clicked")
end

defp stock_price(stocks, stock_name) do
 Map.get(stocks, stock_name)
end

defp portfolio_value(portfolio, stocks) do
 portfolio
 |> Enum.map(fn {stock_name, amount} -> stock_price(stocks, stock_name) * amount end)
 |> Enum.sum()
end

defp execute_order(stock_name, amount, socket) do
 %{:stocks => stocks, :portfolio => portfolio, :balance => balance} = socket.assigns

 {new_portfolio, new_balance} = buy_stock(portfolio, stock_name, amount, stocks, balance)
 new_portfolio_value = portfolio_value(new_portfolio, stocks)

 socket
 |> assign(portfolio: new_portfolio)
 |> assign(portfolio_value: new_portfolio_value)
 |> assign(balance: new_balance)
end

defp buy_stock(portfolio, stock_name, amount, stocks, balance) do
 new_portfolio = Map.update(portfolio, stock_name, 1, &(&1 + amount))
 new_balance = balance + -1 * amount * stock_price(stocks, stock_name)

 {new_portfolio, new_balance}
end

defp new_random_prices(stocks) do
 for {name, value} <-
       stocks,
     into: %{},
     do: {name, value + Enum.random([0, 0, 0, 0, 0, -1, 1, 2])}
end

defp update_stock_prices(%{:assigns => %{:stocks => stocks, :portfolio => portfolio}} = socket) do
 updated_stocks = new_random_prices(stocks)
 updated_portfolio_value = portfolio_value(portfolio, updated_stocks)

 socket
 |> assign(stocks: updated_stocks)
 |> assign(portfolio_value: updated_portfolio_value)
end
end
