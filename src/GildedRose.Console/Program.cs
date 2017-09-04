using System.Collections.Generic;

namespace GildedRose.Console
{
    class Program
    {
        IList<Item> Items;
        static void Main(string[] args)
        {
            System.Console.WriteLine("OMGHAI!");

            var app = new Program()
                          {
                              Items = new List<Item>
                                          {
                                              new Item {Name = "+5 Dexterity Vest", SellIn = 10, Quality = 20},
                                              new Item {Name = "Aged Brie", SellIn = 2, Quality = 0},
                                              new Item {Name = "Elixir of the Mongoose", SellIn = 5, Quality = 7},
                                              new Item {Name = "Sulfuras, Hand of Ragnaros", SellIn = 0, Quality = 80},
                                              new Item
                                                  {
                                                      Name = "Backstage passes to a TAFKAL80ETC concert",
                                                      SellIn = 15,
                                                      Quality = 20
                                                  },
                                              new Item {Name = "Conjured Mana Cake", SellIn = 3, Quality = 6},
                                          }

                          };

            app.UpdateQuality();

            System.Console.ReadKey();

        }

        public void UpdateQuality()
        {
            for (var i = 0; i < Items.Count; i++)
            {
                if (Items[i].Name != "Sulfuras, Hand of Ragnaros")
                {
                    Items[i].SellIn -= 1;
                    if(Items[i].SellIn < 0)
                    {
                        Items[i].SellIn = 0;
                    }
                }

                if (Items[i].Name == "Aged Brie")
                {
                    Items[i].Quality = IncrementQuality(Items[i].Quality, 1);
                }
                else if (Items[i].Name == "Backstage passes to a TAFKAL80ETC concert")
                {
                    if (Items[i].SellIn > 10)
                    {
                        Items[i].Quality = IncrementQuality(Items[i].Quality, 1);
                    }
                    else if (Items[i].SellIn <= 10 && Items[i].SellIn > 5)
                    {
                        Items[i].Quality = IncrementQuality(Items[i].Quality, 2);
                    }
                    else if(Items[i].SellIn <= 5 && Items[i].SellIn >=0)
                    {
                        Items[i].Quality = IncrementQuality(Items[i].Quality, 3);
                    }
                    else
                    {
                        Items[i].Quality = 0;
                    }
                }
                else if (Items[i].Name != "Sulfuras, Hand of Ragnaros")
                {
                    Items[i].Quality = DecrementQuality(Items[i].Quality);
                    if(Items[i].Name == "Conjured Mana Cake")
                    {
                        Items[i].Quality = DecrementQuality(Items[i].Quality);
                    }

                    if (Items[i].SellIn <= 0 && Items[i].Name != "Conjured Mana Cake")
                    {
                        Items[i].Quality = DecrementQuality(Items[i].Quality);
                    }

                }
            }
        }

        // this method add value to quality, and if quality is over 50, it's stay at 50
        private int IncrementQuality(int quality, int value)
        {
            if (quality > 50)
            {
                quality = 50;
            }
            else
            {
                quality += value;
            }
            return quality;
        }

        // This method remove 1 quality, and if quality is under 0, quality stay at 0
        private int DecrementQuality(int quality)
        {
            quality -= 1;
            if(quality < 0)
            {
                quality = 0;
            }
            return quality;
        }
    }

    public class Item
    {
        public string Name { get; set; }

        public int SellIn { get; set; }

        public int Quality { get; set; }
    }

}
