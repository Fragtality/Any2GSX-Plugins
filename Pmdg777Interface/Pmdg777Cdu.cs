using CFIT.AppLogger;
using CFIT.AppTools;
using CFIT.SimConnectLib.SimResources;
using System;
using System.Collections.Generic;
using System.Globalization;
using System.Threading.Tasks;

namespace Pmdg777Interface
{
    public class Pmdg777Cdu(Pmdg777Aircraft aircraft)
    {
        public virtual Pmdg777Aircraft Aircraft { get; } = aircraft;
        public virtual ISimResourceSubscription RotorBrake => Aircraft.SubRotorBrake;
        public virtual int ButtonDelay { get; } = 150;
        protected virtual bool SequenceRunning { get; set; } = false;
        public virtual Dictionary<string, int> Buttons { get; } = new()
        {
            { "MENU", 675 },
            { "L1", 653 },
            { "L2", 654 },
            { "L3", 655 },
            { "L4", 656 },
            { "L5", 657 },
            { "L6", 658 },
            { "R1", 659 },
            { "R2", 660 },
            { "R3", 661 },
            { "R4", 662 },
            { "R5", 663 },
            { "R6", 664 },
            { "DOT", 688 },
        };

        public virtual Dictionary<string, int> Numbers { get; } = new()
        {
            { "0", 678 },
            { "1", 679 },
            { "2", 680 },
            { "3", 681 },
            { "4", 682 },
            { "5", 683 },
            { "6", 684 },
            { "7", 685 },
            { "8", 686 },
            { "9", 687 },
        };

        protected virtual async Task SendRotorBrake(int code, int actionType = 1)
        {
            int evt = (code * 100) + actionType;
            Logger.Verbose($"Sending RotorBrake {code} => {evt}");
            await RotorBrake.WriteValue(evt);
            await Task.Delay(ButtonDelay);
        }

        public virtual async Task SendButton(string button, int actionType = 1)
        {
            if (Buttons.TryGetValue(button, out int code))
            {
                Logger.Debug($"Sending Button '{button}' => {code}");
                await SendRotorBrake(code, actionType);
            }
        }

        public virtual async Task SendNumber(string number)
        {
            Logger.Debug($"Sending Number '{number}'");
            foreach (char chr in number)
            {
                string num = chr.ToString();
                if (int.TryParse(num, out _) && Numbers.TryGetValue(num, out int code))
                {
                    Logger.Debug($"Sending Button '{num}' => {code}");
                    await SendRotorBrake(code);
                }
                else if (num == ".")
                {
                    Logger.Debug($"Sending Button 'DOT' => {Buttons["DOT"]}");
                    await SendRotorBrake(Buttons["DOT"]);
                }
            }
        }

        protected virtual async Task WaitForSequence()
        {
            while (SequenceRunning)
                await Task.Delay(250, Aircraft.Token);
        }

        public virtual async Task<bool> SetFuelOnBoardKg(double fuelKg, bool menu = true)
        {
            bool result = false;
            try
            {
                await WaitForSequence();
                SequenceRunning = true;

                int fuel = Aircraft.WeightInKg ? (int)fuelKg : (int)Aircraft.AppResources.WeightConverter.ToLb(fuelKg);

                if (menu)
                {
                    await SendButton("MENU");
                    await Task.Delay(ButtonDelay * 2);
                }
                await SendButton("R6");
                await SendButton("L1");
                await SendNumber(((int)fuel).ToString());
                await SendButton("L1");
                if (menu)
                    await SendButton("MENU");
                result = true;
            }
            catch (Exception ex)
            {
                if (ex is not TaskCanceledException)
                    Logger.LogException(ex);
            }
            SequenceRunning = false;
            return result;
        }

        public virtual async Task<bool> SetPayloadEmpty()
        {

            bool result = false;
            try
            {
                await WaitForSequence();
                SequenceRunning = true;

                await SendButton("MENU");
                await Task.Delay(ButtonDelay * 2);
                await SendButton("R6");
                await SendButton("L2");
                await SendButton("L5");
                await SendButton("R5");
                await SendButton("MENU");
                result = true;
            }
            catch (Exception ex)
            {
                if (ex is not TaskCanceledException)
                    Logger.LogException(ex);
            }
            SequenceRunning = false;
            return result;
        }

        public virtual async Task<bool> FixPayloadFreighter(double cargoPercent)
        {

            bool result = false;
            try
            {
                if (cargoPercent < 0.0 || cargoPercent > 100.0)
                {
                    Logger.Warning($"Invalid Cargo Percentage: {cargoPercent}");
                    return false;
                }

                await WaitForSequence();
                SequenceRunning = true;

                await SendButton("MENU");
                await Task.Delay(ButtonDelay * 2);
                await SendButton("R6");
                await SendButton("L2");
                await SendButton("L5");
                await SendButton("L2");
                await SendNumber(cargoPercent.ToString("F1", CultureInfo.InvariantCulture));
                await SendButton("R3");
                await SendButton("MENU");
                result = true;
            }
            catch (Exception ex)
            {
                if (ex is not TaskCanceledException)
                    Logger.LogException(ex);
            }
            SequenceRunning = false;
            return result;
        }
    }
}
