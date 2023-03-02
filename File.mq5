#include <Trade\Trade.mqh>

// Masukkan alamat email dan password di sini
input string email_address   = "email_address@outlook.com";
input string email_password  = "email_password";

// Masukkan kata kunci yang akan digunakan untuk membuka perdagangan
input string buy_keyword     = "buy";
input string sell_keyword    = "sell";

// Masukkan simbol yang akan ditradingkan
input string symbols[3] = {"ENQH23", "US100", "EURUSD"};

// Masukkan konfigurasi trading
input double  fixed_lot_size     = 0.01;
input double  stop_loss_percent  = 1;
input double  take_profit_percent = 2;
input double  breakeven_pips     = 10;
input double  trailing_stop_pips = 10;
input bool    use_tpsl           = true;
input bool    trailing_stop      = true;
input bool    breakeven          = true;

// Membuka koneksi dengan akun trading
void OnInit() {
    if (!IsDemo()) {
        if (!Login(email_address, email_password)) {
            Print("Gagal melakukan login ke email : ", GetLastError());
            return;
        }
    }
}

void OnTick() {
    // Mengambil email terbaru
    int email_index = GetIncomingMailTotal()-1;
    if (email_index >= 0) {
        string email_subject = GetEmailSubject(email_index);
        string email_body    = GetEmailBody(email_index);

        // Mencari kata kunci buy atau sell dalam konten email
        bool is_buy = (StringFind(email_body, buy_keyword, 0) >= 0);
        bool is_sell = (StringFind(email_body, sell_keyword, 0) >= 0);

        if (is_buy || is_sell) {
            // Menentukan simbol yang akan ditradingkan
            string symbol = "";
            for (int i=0; i<ArraySize(symbols); i++) {
                if (StringFind(email_body, symbols[i], 0) >= 0) {
                    symbol = symbols[i];
                    break;
                }
            }

            if (symbol != "") {
                // Mengambil harga terbaru dari simbol yang akan ditradingkan
                double price = SymbolInfoDouble(symbol, SYMBOL_ASK);

                // Menghitung stop loss dan take profit dalam nilai absolut atau persentase
                double stop_loss_price;
                double take_profit_price;
                if (use_tpsl) {
                    stop_loss_price = price - (stop_loss_percent / 100.0) * price;
                    take_profit_price = price + (take_profit_percent / 100.0) * price;
                } else {
                    stop_loss_price = price - stop_loss_percent * Point;
                    take_profit_price = price + take_profit_percent * Point;
                }

                // Membuat permintaan untuk membuka perdagangan
                MqlTradeRequest order_request;
                order_request.action    = (is_buy) ? TRADE_ACTION_DEAL : TRADE_ACTION_DEAL;
                order_request.symbol    = symbol;
                order_request.volume    = fixed_lot_size;
                order_request.sl = stop_loss_price;
                order_request.tp = take_profit_price;

            // Membuat permintaan untuk membuka perdagangan
            MqlTradeRequest order_request;
            order_request.action    = (is_buy) ? TRADE_ACTION_DEAL : TRADE_ACTION_DEAL;
            order_request.symbol    = symbol;
            order_request.volume    = fixed_lot_size;
            order_request.sl = stop_loss_price;
            order_request.tp = take_profit_price;
            order_request.type     = ORDER_TYPE_SELL;
            order_request.magic    = 12345;
            order_request.deviation= 5;
            order_request.comment  = "Trade opened by email alert";

            // Mengirim permintaan untuk membuka perdagangan
            MqlTradeResult order_result;
            if (OrderSend(order_request, order_result)) {
                // Perintah berhasil dilaksanakan
                ticket = order_result.order;
                Print("Order ", ticket, " opened with symbol ", symbol, " and volume ", fixed_lot_size);
                if (trailing_stop) {
                    // Mengaktifkan trailing stop
                    double trailing_stop_level = price - trailing_stop_pips * Point;
                    if (OrderSelect(ticket, SELECT_BY_TICKET)) {
                        OrderModify(ticket, order_request.price, trailing_stop_level, order_request.sl, 0, clrNONE);
                        Print("Trailing stop activated for order ", ticket);
                    }
                }
                if (breakeven) {
                    // Mengaktifkan breakeven
                    double breakeven_level = OrderOpenPrice();
                    if (OrderSelect(ticket, SELECT_BY_TICKET)) {
                        OrderModify(ticket, breakeven_level, order_request.tp, order_request.sl, 0, clrNONE);
                        Print("Breakeven activated for order ", ticket);
                    }
                }
            } else {
                // Perintah gagal dilaksanakan
                Print("Failed to open order with error code ", GetLastError());
            }
        }
    }
}
  // Logout dari akun
    if (AccountInfoInteger(ACCOUNT_LOGIN) > 0) {
        Logout();
}